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

      command('team') do |client, data, match|
        slack_id = data.user
        team_name = match['expression'].strip

        member = Member.find(slack_id: slack_id)
        return unless validate_member(client, member)
        return unless validate_memberships(client, member)

        team = member.teams.find { |t| t.name.casecmp(team_name).zero? }
        unless team
          logger.info("#{member.full_name} is not part of #{team_name}")
          client.say(text: "Du ser ikke ut til å være en del av #{team_name}", channel: data.channel)
          return
        end

        member.add_team(team)
        member.save
        client.say(text: "#{team.name} er nå ditt default team", channel: data.channel)
      end

      @slack_team_regex = '\<\#\w+\|(?<team>[[:word:]-]+)\>'
      @literal_team_regex = '\#(?<team>[[:word:]-]+)'
      @report_type_regex = '(?<report>i\s?(går|dag)|problem|(yester|to)day)'
      @command_regex = Regexp.new("(#{@slack_team_regex}|#{@literal_team_regex})?\s*#{@report_type_regex}", Regexp::IGNORECASE)

      command(@command_regex) do |client, data, match|
        report_to_standup(client, data, match)
      end

      def self.report_to_standup(client, data, match)
        team_name = match['team']
        report_type = command_to_sym(match['report'])
        message = Rumoji.decode(match['expression'])
        slack_id = data.user

        member = Member.find(slack_id: slack_id)
        return unless validate_member(client, member)
        return unless validate_memberships(client, member)
        team = find_team(client, team_name, member)
        if team.nil?
          logger.info("#{member.full_name} sent a message missing team name: #{message}")
          client.say(text: 'Du mangler teamnavn i meldingen din, start '\
                           'meldingen med `#team_name`.\nFor eksempel: '\
                           '`#aura i dag er jeg på kotlin workshop`\n'\
                           'Du er medlem av følgende team: '\
                           "#{member.teams.map(&:name)}",
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

        report.update(report_type => message)
        report.save
        client.say(text: "notert (for https://standup.nais.io/team/#{team.name})", channel: data.channel)
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

      def self.validate_member(client, member)
        return true if member
        logger.info("Can't find member with slack id #{slack_id}")
        client.say(text: 'Du ser ikke ut til å være registrert i et team', channel: data.channel)
        false
      end

      def self.validate_memberships(client, member)
        if member.teams.empty?
          logger.info("#{member.full_name} has no membership")
          client.say(text: 'Du ser ikke ut til å være registrert i et team', channel: data.channel)
          return false
        end
        true
      end

      def self.find_team(client, team_name, member)
        team = nil
        if team_name
          team = member.teams.find { |t| t.name.casecmp(team_name).zero? }
          unless team
            logger.info("#{member.full_name} is not part of #{team_name}")
            client.say(text: "Du ser ikke ut til å være en del av #{team_name}", channel: data.channel)
            return nil
          end
        elsif member.teams.size == 1
          team = member.teams.first
        elsif member.team
          team = member.team
        end

        team
      end
    end
  end
end
