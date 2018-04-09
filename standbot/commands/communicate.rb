require 'date'

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

      command /(i\s?(går|dag)|problem|(yester|to)day)/i do |client, data, match|
        user_id = data.user
        user = client.users[user_id]
        command = command_to_sym(match['command'])
        message = match['expression']
        member = Member.find(slack_id: user_id)
        unless member
          client.say(text: 'Du ser ikke ut til å være registrert i noen team', channel: data.channel)
          return
        end

        membership = Membership.find(member_id: member.id)
        unless membership
          client.say(text: 'Du ser ikke ut til å være registrert i noen team', channel: data.channel)
          return
        end

        team = Team[membership.team_id]
        standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => Date.today)
        if standup.nil?
          standup = Standup.new
          team.add_standup(standup)
          standup.save
        end

        report = Report.find(member_id: member.id, standup_id: standup.id, Sequel.function(:date, :created_at) => Date.today)
        if report.nil?
          report = Report.new
          member.add_report(report)
          standup.add_report(report)
          report.save
        end

        report.update(command => message)
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
        end
      end
    end
  end
end
