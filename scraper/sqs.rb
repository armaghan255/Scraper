require 'aws-sdk-sqs'
require 'securerandom'
require 'dotenv/load'

module Scraper
  module Sqs

    def get_aws_sqs
      access_key_id = ENV['AWS_ACCESS_KEY']
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      client = Aws::SQS::Client.new({region: 'us-east-1',credentials: credentials})
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts "Exception occured"
      puts e.message
    end

    def get_queue_url(queue_name)
      client = get_aws_sqs
      client.get_queue_url(queue_name: queue_name).queue_url
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts "Exception occured"
      puts e.message
    end

    def send_msg(msg,queue_name)
      client = get_aws_sqs
      response = client.send_message({queue_url: get_queue_url(queue_name), message_body: msg.to_json,message_deduplication_id: SecureRandom.uuid,message_group_id: "Walmart"})
      if response.message_id
        puts '---Message successfully delivered---'
        puts response.message_id
      else
        puts '---Unable to deliver message Error occured---'
      end
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts e.message
    end

    def receive_msg(queue_name,visibility_timeout = 60)
      client = get_aws_sqs
      response = client.receive_message({queue_url: get_queue_url(queue_name), visibility_timeout: visibility_timeout,})
      puts '---Messages Received---'
      response.messages.each do |message|
        puts message.body
      end
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts "Exception occured"
      puts e.message
    end

    def delete_msg(queue_name, receipt_handle)
      client = get_aws_sqs
      response = client.delete_message({queue_url: get_queue_url(queue_name), receipt_handle: receipt_handle})
      puts '---Message successfully deleted---'
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts "Exception occured"
      puts e.message
    end

    def change_visibility(queue_name, receipt_handle, visibility_timeout)
      client = get_aws_sqs
      response = client.change_message_visibility({queue_url: get_queue_url(queue_name), receipt_hanlde: receipt_handle, visibility_timeout: visibility_timeout})
      puts '---Visibility successfully changed---'
    rescue Aws::SQS::Errors => e
      puts e.message
    rescue => e
      puts "Exception occured"
      puts e.message
    end
  end
end
