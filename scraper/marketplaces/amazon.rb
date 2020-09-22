require_relative "scraper_base"

module Scraper
  module Marketplaces

    class Amazon < ScraperBase

      public

        def initialize
          @retries = 0
          @offers = {}
          start
        end

        def start
          set_scrapper
          agent = Mechanize.new
          @asins.each do |asin|
            puts asin
            get_asin_offers(agent, asin)
            puts @offer
            #send_msg(@offers[asin.to_sym])
          end
          save_data
        end


      private
        def save_data
          CSV.open("asin_offers.csv", "wb") do |csv|
            csv << ["Asin","Seller Id", "Price","Condition","Delivery","Seller","Rating"]
            @offers.each do |asin, offers|
              offers.each {|offer| csv <<  offer.values }
            end
          end
          puts @offers.size
        end

        def set_scrapper
          @user_agents = File.read("useragents.txt").split(":").map(&:strip)
          @asins = File.read("asins.txt").split(",")
        end

        def set_seller(seller)
          if seller
            seller = seller['href'].match(/seller=\w*/).to_s.gsub("seller=","")
          else
            seller = nil
          end
          seller
        end

        def get_asin_offers(agent, asin)

          @offers[asin.to_sym] = []
          agent.user_agent = @user_agents.sample
          page = agent.get("https://www.amazon.com/gp/offer-listing/#{asin}")

          total_index = page.search('.a-pagination li ~ :nth-last-child(2)').text[/Page(\d{,2})/,1]
          total_index ||= "1"
          total_index = total_index.to_i - 1
          0.upto(total_index) do |index|

            page = agent.get("https://www.amazon.com/gp/offer-listing/#{asin}?startIndex=#{index*10}") unless index == 0
            get_offers(asin, page)
          end

        end

        def get_offers(asin, page)
          begin
            elements = page.search('.olpOffer')
            if elements.size > 0
              elements.each do |element|
                offer = {}
                offer[:asin] = asin
                offer[:seller_id] = set_seller(element.search('.olpSellerName a[href*="seller"]')&.first)
                offer[:price] = element.search(".olpOfferPrice").text.strip
                offer[:condition] = element.search(".olpCondition").text.strip.gsub("\n", '').gsub(/\s+/," ")
                offer[:delivery] = element.xpath(".//li[contains(., 'Ships from')]").text.gsub("Ships from", '').strip.gsub("\n", '')
                offer[:seller] = element.search("h3.olpSellerName span").text.strip
                offer[:rating] = element.search("div.olpSellerColumn p a b").text.strip
                offer[:rating] = offer[:rating][0..1]
                @offers[asin.to_sym] << offer
                end
            else
              @offers[asin.to_sym] << {:asin => asin}
            end

          rescue Mechanize::ResponseCodeError
            puts '...Test...'
            puts '503 exception occured'
            agent.user_agent = @user_agents.sample
            @retries += 1
            retry if @retries < 3
          end
        end

    end

  end
end
