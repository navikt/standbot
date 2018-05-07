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

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
          else
            teams = Team.active
          end

          teams.each do |team|
            logger.info("Standup for #{team.name}")

            team.members.each do |member|
              im = client.im_open(user: member.slack_id)
              im_channel_id = im && im['channel'] && im['channel']['id']
              next unless im_channel_id
              if notified.include?(member.full_name)
                logger.info("#{member.full_name} is already notified, skipping this time")
                next
              end
              logger.info("Notifying #{member.full_name}")
              message = "Tid for stand-up!\nRapporter tilbake med "
              unless Date.today.monday?
                message += "`i går`, "
              end
              message += "`i dag`, og `problem`.\n"

              if member.teams.size > 1
                message += 'Du er med i flere team, og må da spesifisere team '\
                           'for rapportere per team. Alt du trenger å gjøre er '\
                           'å starte kommandoen din med  #teamnavn.\n'\
                           'For eksempel: `#aura i dag er jeg på kotlin workshop`'\
                           "\nDu er medlem i følgende teams: #{member.teams.map { |team| team.name }}"
              else
                message += "For eksempel: `i går satt jeg i møter hele dagen`.\n"\
                           "Se team-rapporten på https://standup.nais.io/team/#{team.name}"
              end
              client.chat_postMessage(text: message, channel: im_channel_id)
              notified.append(member.full_name)
            rescue Slack::Web::Api::Errors::SlackError => e
              puts e
            end
          end

          return 'OK'
        end

        get '/daily_summary/?' do
          logger.info('Running summaries for team')
          if red_day?
            logger.info('No summaries on red days')
            return 'RED_DAY'
          end

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
          else
            teams = Team.active
          end

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])

          teams.each do |team|
            next unless team.channel && team.summary
            slack_channel = client.channels_list.channels.find { |channel| channel.name == team.channel.name }
            slack_channel = client.groups_list.groups.find { |channel| channel.name == team.channel.name } unless slack_channel

            unless slack_channel
              logger.error("The channel ##{team.channel.name} doesn't exist")
              next
            end

            standup = team.todays_standup.first
            message = standup.reports.each do |report|
              text = "#{report.member.full_name} rapporterte:"
              attachments = []
              attachments << { color: '#add8e6', text: "I går: #{report.yesterday}" } if report.yesterday
              attachments << { color: '#90ee8f', text: "I dag: #{report.today}" } if report.today
              attachments << { color: '#f17f7f', text: "Problem: #{report.problem}" } if report.problem
              client.chat_postMessage(text: text, attachments: attachments, channel: slack_channel.id)
            end
          end

          return 'OK'
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
