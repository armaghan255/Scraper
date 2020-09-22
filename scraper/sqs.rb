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
    end

    def get_queue_url
      client = get_aws_sqs
      client.get_queue_url(queue_name: "Walmart-products-test.fifo").queue_url
    end

    def send_msg(msg)
      begin
        client = get_aws_sqs
        response = client.send_message({queue_url: get_queue_url, message_body: msg.to_json,message_deduplication_id: SecureRandom.uuid,message_group_id: "Walmart"})
        if response.message_id

          puts '---Message successfully delivered---'
          puts response.message_id
        else
          puts '---Unable to deliver message Error occured---'
        end

      rescue Aws::SQS::Errors => e
        puts e.message
      end


    end

    def receive_msg(visibility_timeout = 60)
      client = get_aws_sqs
      response = client.receive_message({queue_url: get_queue_url, visibility_timeout: visibility_timeout,})
      puts '---Messages Received---'
      response.messages.each do |message|
        puts message.body
      end
    end

    def delete_msg(queue_url, receipt_handle)
      client = get_aws_sqs
      response = client.delete_message({queue_url: queue_url, receipt_handle: receipt_handle})
      puts '---Message successfully deleted---'
    end

    def change_visibility(queue_url, receipt_handle, visibility_timeout)
      client = get_aws_sqs
      response = client.change_message_visibility({queue_url: queue_url, receipt_hanlde: receipt_handle, visibility_timeout: visibility_timeout})
      puts '---Visibility successfully changed---'
    end
  end
end
