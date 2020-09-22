require_relative "scraper_base"

module Scraper
  module Marketplaces
    class Walmart < ScraperBase
      def initialize(name = 'walmart')
        @retries = 0
        @results = []
        @log = Logger.new("log/#{name}")
        start
      end

      def start
        agent = Mechanize.new
        get_results(agent) do |query, page_number|
          begin
            query.gsub(/\s/,"+")
            agent.get("https://www.walmart.com/search/?page=#{page_number}&query=#{query}")
          rescue Mechanize::ResponseCodeError
            puts '503 exception occured'
            agent.user_agent = UserAgent.random
            retry
          end
        end
      end

      private
        def save_data_to_csv
          CSV.open("song of ice and fire.csv", "wb") do |csv|
            csv << ["Id","Title","Rating", "Reviews","Image Url","Price"]
            @results.each {|result| csv << result.values }
          end
        end

        def get_form(agent)
          begin
            page = agent.get("https://www.walmart.com/")
            page.form(id: "global-search-form")
          rescue Mechanize::ResponseCodeError
            puts '503 exception occured'
            agent.user_agent = UserAgent.random
            retry
          end
        end

        def search_query(form, query)
          form['query'] = query
          form.submit
        end

        def get_total_pages(page)
          summary = page.search(".result-summary-container").text
          summary = summary.match(/to\s(\d*) of\s(\d*)/)
          total_on_page = summary[1]
          overall_total = summary[2]
          total_pages = overall_total.to_f / total_on_page.to_f
          @log.info("Total Pages : " + total_pages.to_s)
          total_pages.ceil
        end

        def find_image_url(element)
          begin
            image_url = element.search(".prod-hero-image img").first['srcset']
          rescue
            image_url = "Missing Url"
          end
        end

        def get_results(agent, &block)
          agent.user_agent = UserAgent.random
          search_page = search_query(get_form(agent), "song of ice and fire")
          total_index = get_total_pages(search_page)
          extract_results(agent, total_index, search_page, &block)
        end

        def extract_data(agent, id)
          begin
            element = agent.get("https://www.walmart.com/ip/#{id}").search("#product-overview")
            result = {}
            result[:id] = id
            result[:title] = element.xpath("//h1[contains(@class,'prod-ProductTitle')]").text
            result[:rating] = element.xpath("//span[starts-with(@itemprop,'ratingValue')]").text
            result[:rating] = "0" if result[:rating].empty?
            result[:reviews] = element.search(".stars-reviews-count-node").text[/(\d*)/]
            result[:reviews] = "0" if result[:reviews].empty?
            result[:image_url] = find_image_url(element)
            result[:price] = element.search("section.prod-PriceSection .prod-PriceHero span.hide-content-m span.visuallyhidden").first.text
            @log.info(result)
          rescue Mechanize::ResponseCodeError
            puts '503 exception occured'
            agent.user_agent = UserAgent.random
            retry
          rescue => e
            @log.error(e.inspect)
            puts 'Exception occurred during scraping'
          end
          result
        end

        def extract_results(agent, total_index, search_page, &block)
          queue = Queue.new
          threads = []
          1.upto(total_index) do |index|
            agent.user_agent = UserAgent.random
            search_page = block.("song of ice and fire", index) unless index == 1
            ids = search_page.body.match(/itemIds":"[(\d*),]*/).to_s.gsub(/itemIds":"/,'').split(",")
            ids.each { |id| queue << id }
            10.times do
              threads << Thread.new {
                until queue.empty?
                  begin
                    @results << extract_data(agent, queue.deq)
                  rescue ThreadError => e
                    @log.error(e.inspect)
                    puts e.message
                  rescue => e
                    @log.error(e.inspect)
                    puts e.message
                  end
                end
              }
            end
            threads.each(&:join)
          end
          save_data_to_csv
          send_msg(@results,"Walmart-products-test.fifo")
        end
    end
  end
end
