# frozen_string_literal: true

require 'date'
require 'httparty'

module Standweb
  class Web < Sinatra::Base
    register Sinatra::Namespace

    namespace '/api/?' do
      namespace '/v1/?' do
        get '/standup/?' do
          logger.info('Time for standup')
          if red_day?
            logger.info('No standup on red days')
            return 'RED_DAY'
          end

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          notified = []
          Team.active.each do |team|
            logger.info("Standup for #{team.name}")

            team.members.each do |member|
              im = client.im_open(user: member.slack_id)
              im_channel_id = im && im['channel'] && im['channel']['id']
              next unless im_channel_id
              if notified.include?(member.full_name)
                logger.info("#{member.full_name} already notified, skipping")
                next
              end
              logger.info("Notifying #{member.full_name}")
              message = "Tid for standup!\nRapporter tilbake med 'i går', 'i dag', og" \
                        "'problem'\nFor eksempel `i går satt jeg i møter hele dagen`"
              if member.teams.size > 1
                message += "\nDu er medlem i følgende teams: #{member.teams.map { |team| team.name }}"
              end
              client.chat_postMessage(text: message, channel: im_channel_id)
              notified.append(member.full_name)
            rescue Slack::Web::Api::Errors::SlackError => e
              puts e
            end
          end

          return 'OK'
        end
      end
    end

    def red_day?(date = nil)
      year = (date || Date.today).year
      api_url = "https://webapi.no/api/v1/holydays/#{year}"
      response = HTTParty.get(api_url)
      if response.success?
        response.parsed_response['data'].each do |data|
          return true if Date.strptime(data['date'], '%Y-%m-%d').to_date == date
        end
      end
      false
    end
  end
end
