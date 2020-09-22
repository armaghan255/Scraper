require_relative "marketplaces/amazon"
require_relative "marketplaces/walmart"

module Scraper
  class InitiateScraper
    include Scraper::Marketplaces
    def initialize(name)
      @scraper = Object.const_get("Scraper::Marketplaces::" + name).new
    end

    def start_scraper
      @scraper.start
    end
  end
end

print "Enter scraper name : "
Scraper::InitiateScraper.new(gets.chomp)
