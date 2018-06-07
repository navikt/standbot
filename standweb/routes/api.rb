# frozen_string_literal: true

require 'date'
require 'httparty'

module Standweb
  class Web < Sinatra::Base
    register Sinatra::Namespace

    namespace '/api/?' do
      namespace '/v1/?' do
        get '/standup/?' do
          logger.info('Time for stand-up')
          if red_day?
            logger.info('No stand-up on red days')
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
              message += '`i går`, ' unless Date.today.monday?
              message += "`i dag`, og `problem`.\n"

              message += if member.teams.size > 1
                           'Du er med i flere team, og må da spesifisere team '\
                           'i rapporten din. Alt du trenger å gjøre er '\
                           "å starte kommandoen din med  #teamnavn.\n"\
                           'For eksempel: `#aura i dag er jeg på kotlin workshop`'\
                           "\nDu er medlem i følgende teams: #{member.teams.map(&:name).join(', ')}\n"
                         else
                           "For eksempel: `i går satt jeg i møter hele dagen`.\n"\
                           "Se team-rapporten på https://standup.nais.io/team/#{team.name}"
                         end

              client.chat_postMessage(text: message, channel: im_channel_id)
              notified.append(member.full_name)
            rescue Slack::Web::Api::Errors::SlackError => e
              puts e
            end
          end

          'OK'
        end

        get '/daily_summary/?' do
          logger.info('Running summaries for teams')
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
            slack_channel ||= client.groups_list.groups.find { |channel| channel.name == team.channel.name }

            unless slack_channel
              logger.error("The channel ##{team.channel.name} doesn't exist")
              next
            end

            standup = team.todays_standup
            if standup.nil?
              logger.info("No stand-up to summaries for #{team.name}")
              next
            end

            attachments = []
            standup.reports.each do |report|
              text = ""
              text += "*I går:* #{report.yesterday}\n" if report.yesterday
              text += "_*I går:* #{report.yesterday_report.today}_\n" if report.yesterday_report && report.yesterday.nil?
              text += "*I dag:* #{report.today}\n" if report.today
              text += "*Problem:* #{report.problem}" if report.problem

              attachments <<
              {
                fallback: "fallback",
                author_name: report.member.full_name,
                author_icon: report.member.avatar_url,
                mrkdwn_in: [ "text" ],
                text: text,
                ts: report.created_at.to_i
              }
            end
            logger.info("Sending #{attachments.size} reports for #{team.name} with #{team.members.size} members")
            client.chat_postMessage(text: "Dagens rapport", attachments: attachments, channel: slack_channel.id)
          end

          'OK'
        end

        get '/daily_reminder/?' do
          logger.info('Daily reminder of stand-up')
          if red_day?
            logger.info('No stand-up on red days')
            return 'RED_DAY'
          end

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
          else
            teams = Team.active
          end

          reminders = {}
          teams.each do |team|
            standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => Date.today)
            team.members.each do |member|
              next if standup&.members&.include?(member)
              reminders[member.full_name] ||= {}
              reminders[member.full_name]['teams'] ||= []
              reminders[member.full_name]['teams'] << team.name
              reminders[member.full_name]['slack_id'] = member.slack_id
            end
          end

          reminders.each do |full_name, reminder|
            im = client.im_open(user: reminder['slack_id'])
            im_channel_id = im && im['channel'] && im['channel']['id']
            next unless im_channel_id
            logger.info("Reminding #{full_name} of stand-up for #{reminder['teams'].join(', ')}")
            message = "En påminnelse om at du ikke har vært på stand-up i dag for #{reminder['teams'].join(', ')}"
            client.chat_postMessage(text: message, channel: im_channel_id)
          end

          'OK'
        end

        get '/notify/?' do
          message = params['message']
          return 'MISSING MESSAGE' unless message

          if params['team']
            team_name = params['team']
            teams = Team.where(Sequel.ilike(:name, team_name))
          else
            teams = Team.active
          end

          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          logger.info("Sending message: #{message}")
          teams.each do |team|
            notified = []
            logger.info("Sending message to #{team.name}")
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

          'OK'
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
