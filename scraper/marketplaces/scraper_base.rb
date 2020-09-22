require 'mechanize'
require 'csv'

require_relative "./../sqs"
require_relative "../../user_agent"
require "logger"

module Scraper
  module Marketplaces
    class ScraperBase
      include Sqs

    end
  end
end
