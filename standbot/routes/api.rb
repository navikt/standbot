require 'date'
require 'httparty'

module Standbot
  class StandWeb < Sinatra::Application
    get '/api/standup/?' do
      # old school debug
      p headers
      p headers['Appengine-Cron']
      p request
      p request.ip
      p request.env['REMOTE_ADDR'].split(',').first
      # end

      # TODO: check if it's time for standup, should be able to change this
      # with an environment variable.
      # Maybe we should use some form of API token here?

      return 'RED_DAY' if red_day?
            
      client = Imbot.client
      channel = client.groups_info(channel: '#aura').group
      channel.members.each do |slackid|
        imid = Imbot.im_open!(slackid)
        next unless imid
        client.chat_postMessage(text: "Tid for standup!\nRapporter tilbake med 'i går', 'i dag', 'problem'", channel: imid) if imid
      end

      return 'OK'
    end

    def red_day?
      today = Date.today
      year = today.year
      api_url = "https://webapi.no/api/v1/holydays/#{year}"
      response = HTTParty.get(api_url)
      if response.success?
        parsed_response = response.parsed_response
        parsed_response['data'].each do |data|
          return true if Date.strptime(data['date'], '%Y-%m-%d').to_date == Date.today
        end
      end
      return false
    end
  end

  class Imbot
    # Get the bot's Slack API client
    def self.client
      @slack_client ||= ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
    end

    # returns the channel id of an open IM channel
    def self.im_open!(user_slack_id)
      @im_opens ||= {}
      return @im_opens[user_slack_id] if @im_opens[user_slack_id]

      begin
        im = client.im_open(user: user_slack_id)
        im_channel_id = im && im['channel'] && im['channel']['id']
        return @im_opens[user_slack_id] = im_channel_id
      rescue StandardError => err
        STDERR.puts "Error opening IM channel: #{user_slack_id}, with the following error:\n#{err}"
        return nil
      end
    end
  end
end
