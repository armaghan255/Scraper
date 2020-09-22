require 'mechanize'
require 'csv'

require_relative "./../sqs"

module Scraper
  module Marketplaces

    class ScraperBase
      include Sqs

      def initialize
        set_scrapper
      end


      private
        def set_scrapper
          @user_agents = File.read("useragents.txt").split(":").map(&:strip)
        end
    end

  end

end
