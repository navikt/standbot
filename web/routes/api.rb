# frozen_string_literal: true

require 'date'
require 'httparty'

module Standweb
  class Web < Sinatra::Base
    register(Sinatra::Namespace)
    register(Sinatra::JSON)

    namespace '/api/?' do
      namespace '/v2/?' do
        get '/jobs' do
          if red_day?
            logger.info('Nothing to do on red days')
            return json(message: 'No notification on red days')
          end
          time = params['time']
          return json(message: "Query param 'time' is missing") unless time
          time.insert(time.length - 2, ':') unless time.include?(':')

          logger.info("It's #{time}, time to do some work")

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
            return json(message: "Can't find a team named #{team_name}") if teams.empty?
          else
            teams = Team.active
          end

          standup_teams = []
          reminder_teams = []

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          teams.each do |team|
            next unless team.day_for_standup?(Date::DAYNAMES[Date.today.cwday])
            if team.time_for_standup?(time)
              standup_teams.append(team)
            elsif team.time_for_reminder?(time)
              reminder_teams.append(team)
            elsif team.time_for_summary?(time)
              run_summary(client, team)
            end
          end

          run_standup(client, standup_teams) unless standup_teams.empty?
          run_reminder(client, reminder_teams) unless reminder_teams.empty?

          json(message: 'OK')
        end

        get '/notify/?' do
          message = params['message']
          return json(message: "Query param 'message' is missing") unless message

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
            return json(message: "Can't find a team named #{team_name}") if teams.empty?
          else
            teams = Team.active
          end

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          logger.info("Sending message: #{message}")
          notified = []
          teams.each do |team|
            logger.info("Sending message to team #{team.name}")
            team.members.each do |member|
              if notified.include?(member.full_name)
                logger.info("#{member.full_name} is already notified")
                next
              end
              im = client.im_open(user: member.slack_id)
              im_channel_id = im && im['channel'] && im['channel']['id']
              next unless im_channel_id
              logger.info("Sending message to #{member.full_name}")
              client.chat_postMessage(text: message, channel: im_channel_id)
              notified.append(member.full_name)
            end
          end

          json(message: 'OK')
        end

        get '/update_slack_info' do
          updates = 0
          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          Member.all.each do | member |
            response = HTTParty.get(member.avatar_url)
            unless response.success?
              user = client.users_info(user: member.slack_id).user
              member.avatar_url = user.profile.image_72
              member.save
              updates += 1
            end
          end
          json(message: "Updated avatar informatin for #{updates} member(s)")
        end
      end
    end

    def red_day?(date = Date.today)
      year = date.year
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
