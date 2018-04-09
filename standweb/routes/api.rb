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
          Team.active.each do |team|
            logger.info("Standup for #{team.name}")
            standup = Standup.find(Sequel.function(:date, :created_at) => Date.today)
            standup ||= Standup.new
            team.add_standup(standup)
            standup.save

            team.members.each do |member|
              unless Report.find(:member_id => member.id, :standup_id => standup.id, Sequel.function(:date, :created_at) => Date.today)
                Report.create(member_id: member.id, standup_id: standup.id)
              end

              begin
                im = client.im_open(user: member.slack_id)
                im_channel_id = im && im['channel'] && im['channel']['id']
                next unless im_channel_id
                logger.info("Notifying #{member.full_name}")
                client.chat_postMessage(text: "Tid for standup!\nRapporter tilbake med 'i går', 'i dag', 'problem'\nFor eksempel `i går satt jeg i møter hele dagen`", channel: im_channel_id)
              rescue Slack::Web::Api::Errors::SlackError => e
                puts e
              end
            end
          end

          return 'OK'
        end
      end
    end

    def red_day?(date = nil)
      date ||= Date.today
      year = date.year
      api_url = "https://webapi.no/api/v1/holydays/#{year}"
      response = HTTParty.get(api_url)
      if response.success?
        parsed_response = response.parsed_response
        parsed_response['data'].each do |data|
          return true if Date.strptime(data['date'], '%Y-%m-%d').to_date == date
        end
      end
      false
    end
  end
end
