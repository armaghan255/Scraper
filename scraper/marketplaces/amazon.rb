require_relative "scraper_base"

module Scraper
  module Marketplaces

    class Amazon < ScraperBase
      def initialize(name = 'amazon')
        @retries = 0
        @offers = {}
        @log = Logger.new("log/#{name}")
        start
      end

      def start
        set_scrapper
        agent = Mechanize.new
        @asins.each do |asin|
          get_asin_offers(agent, asin)
          @log.info(@offers[asin.to_sym])
          send_msg(@offers[asin.to_sym],"amazon-offers-scraper-testing.fifo")
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
        end

        def set_scrapper
          @asins = File.read("asins.txt").split(",")
        rescue => e
          puts e.inspect
          exit
        end

        def get_seller(seller)
          if seller
            seller = seller['href'].match(/seller=\w*/).to_s.gsub("seller=","")
          else
            seller = nil
          end
        end

        def get_address(element)
          address = element.xpath(".//li[contains(., 'Ships from')]").text.gsub("Ships from", '').strip.gsub("\n", '')
          dot_index = address.index(".")
          address[0..dot_index]
        end

        def get_asin_offers(agent, asin)
          @offers[asin.to_sym] = []
          agent.user_agent = UserAgent.random
          page = agent.get("https://www.amazon.com/gp/offer-listing/#{asin}")
          total_index = page.search('.a-pagination li ~ :nth-last-child(2)').text[/Page(\d{,2})/,1]
          total_index ||= "1"
          total_index = total_index.to_i - 1
          0.upto(total_index) do |index|
            begin
              page = agent.get("https://www.amazon.com/gp/offer-listing/#{asin}?startIndex=#{index*10}") unless index == 0
              get_offers(asin, page)
            rescue => exception
              agent.user_agent = UserAgent.random
              retry
            end
          end
        end

        def get_offers(asin, page)
          elements = page.search('.olpOffer')
          if elements.size > 0
            elements.each do |element|
              offer = {}
              offer[:asin] = asin
              offer[:seller_id] = get_seller(element.search('.olpSellerName a[href*="seller"]')&.first)
              offer[:price] = element.search(".olpOfferPrice").text.strip
              offer[:condition] = element.search(".olpCondition").text.strip.gsub("\n", '').gsub(/\s+/," ")
              offer[:delivery] = get_address(element)
              offer[:seller] = element.search("h3.olpSellerName span").text.strip
              offer[:rating] = element.search("div.olpSellerColumn p a b").text.strip
              offer[:rating] = offer[:rating][0..1]
              @offers[asin.to_sym] << offer
            end
          else
            @offers[asin.to_sym] << {:asin => asin}
          end
        rescue => e
          puts e.message
          @offers[asin.to_sym] << {}
        end
    end
  end
end
