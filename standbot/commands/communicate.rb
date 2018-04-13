# frozen_string_literal: true
require 'date'
require 'rumoji'

module Standbot
  module Commands
    class Communicate < SlackRubyBot::Commands::Base
      help do
        title 'Standbot'
        desc 'This bot inform you about standup, and notify the team'

        command 'igår' do
          desc 'Report activity for each question'
        end

        command 'idag' do
          desc 'Report activity for each question'
        end

        command 'problem' do
          desc 'Report activity for each question'
        end
      end

      @slack_team_regex = /\<\#\w+\|(?<team>[[:word:]-]+)\>/
      @literal_team_regex = /\#(?<team>[[:word:]-]+)/
      @report_type_regex = /(?<report>i\s?(går|dag)|problem|(yester|to)day)/
      @command_regex = Regexp.new(%r{(#{@slack_team_regex}|#{@literal_team_regex})?\s*#{@report_type_regex}}i)

      command(@command_regex) do |client, data, match|
        report_to_standup(client, data, match)
      end

      def self.report_to_standup(client, data, match)
        team_name = match['team']
        report_type = command_to_sym(match['report'])
        message = match['expression']
        slack_id = data.user

        member = Member.find(slack_id: slack_id)
        unless member
          logger.info("Can't find member with slack id #{slack_id}")
          client.say(text: 'Du ser ikke ut til å være registrert i et team', channel: data.channel)
          return
        end

        memberships = Membership.where(member_id: member.id).all
        if memberships.empty?
          logger.info("#{member.full_name} has no membership")
          client.say(text: 'Du ser ikke ut til å være registrert i et team', channel: data.channel)
          return
        end

        if team_name
          membership = memberships.find { |m| m.team.name.casecmp(team_name).zero? }
          unless membership
            logger.info("#{member.full_name} is not part of #{team_name}")
            client.say(text: "Du ser ikke ut til å være en del av #{team_name}", channel: data.channel)
            return
          end
        elsif memberships.size == 1
          membership = memberships.first
        else
          logger.info("#{member.full_name} sent a message missing team name: #{message}")
          client.say(text: 'Du mangler teamnavn i meldingen din, start '\
                           "meldingen med `#team_name`.\nDu er medlem av "\
                           "følgende team: #{memberships.map { |m| m.team.name }}",
                     channel: data.channel)
          return
        end

        team = membership.team
        standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => Date.today)
        if standup.nil?
          logger.info("No standup is created for #{team.name}, creating a new one now")
          standup = Standup.new
          team.add_standup(standup)
          standup.save
        end

        report = Report.find(member_id: member.id, standup_id: standup.id, Sequel.function(:date, :created_at) => Date.today)
        if report.nil?
          logger.info("No report exists for todays standup (##{standup.id}) and #{member.full_name}")
          report = Report.new
          member.add_report(report)
          standup.add_report(report)
          report.save
        end

        report.update(report_type => slack_emoji_to_unicode(message))
        report.save
        client.say(text: "notert (for #{team.name})", channel: data.channel)
      end

      def self.command_to_sym(cmd)
        case cmd
        when /(i\s?går|yesterday)/i
          :yesterday
        when /(i\s?dag|today)/i
          :today
        when /problem/i
          :problem
        else
          logger.info("Unknown command: #{cmd}")
          cmd.to_sym
        end
      end

      def self.slack_emoji_to_unicode(message)
        return Rumoji.decode(message)
      end
    end
  end
end
