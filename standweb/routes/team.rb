# frozen_string_literal: true

module Standweb
  class Web < Sinatra::Base
    namespace '/team/?' do
      get '/new/?' do
        team = Team.new
        haml(:'team/new', locals: { team: team })
      end

      post '/create/?' do
        team_name = params['name'].strip.force_encoding('utf-8')

        if team_name.empty?
          flash.next['error'] = 'Team navn kan ikke være blank'
          redirect('/team/new')
        end

        if Team.find(Sequel.ilike(:name, team_name))
          flash.next['error'] = 'Team navn eksisterer'
          redirect('/team/new')
        end

        team = Team.new(name: team_name)

        channel_name = params['channel'].strip.delete_prefix('#')
        summary = params['summary']

        team.avatar_url = params['avatar_url'].strip
        team.standup_time = params['standup_time'].strip

        unless team.valid?
          flash.next['error'] = team.errors.full_messages.join('\n')
          redirect('/team/new')
        end

        if summary
          if channel_name.empty?
            flash.next['error'] = 'Trenger slack-kanal for å få daglig oppdatering'
            redirect('/team/new')
          end

          team.summary = true
        else
          team.summary = false
        end
        team.save

        unless channel_name.empty?
          channel = Channel.find(name: channel_name)
          channel ||= Channel.create(name: channel_name)
          channel.add_team(team)
          channel.save
        end

        standup_days = params["standup_days"]
        if standup_days
          standup_days.each do |day|
            team.add_standup_day(name: day)
          end
        end

        redirect("/team/#{team.name}/members/add")
      end

      get '/:team_name/edit/?' do |team_name|
        team = Team.find(Sequel.ilike(:name, team_name))
        unless team
          flash.next['error'] = "Team #{team_name} finnes ikke"
          redirect('/team/new')
        end

        haml(:'team/edit', locals: { team: team }, layout: :'team/layout')
      end

      post '/:team_name/update' do
        team_name = params['team_name'].strip.force_encoding('utf-8')
        name = params['name'].strip
        channel_name = params['channel'].strip.delete_prefix('#').downcase
        reminder = params['reminder']
        summary = params['summary']

        if name.empty?
          flash.next['error'] = 'Navn på team kan ikke være blankt'
          redirect("/team/#{team_name}/edit")
        end

        team = Team.find(Sequel.ilike(:name, name))
        if team && name != team_name
          flash.next['error'] = "Team #{team_name} finnes fra før av"
          redirect("/team/#{team_name}/edit")
        end

        team.avatar_url = params['avatar_url'].strip
        team.standup_time = params['standup_time'].strip

        unless team.valid?
          flash.next['error'] = team.errors.full_messages.join('<br />')
          redirect("/team/#{team_name}/edit")
        end

        if summary
          if channel_name.empty?
            flash.next['error'] = 'Trenger slack-kanal for å få daglig oppdatering'
            redirect("/team/#{team_name}/edit")
          end

          team.summary = true
        else
          team.summary = false
        end

        team.reminder = reminder == 'on'
        team.save

        unless channel_name.empty?
          channel = Channel.find(name: channel_name)
          channel ||= Channel.create(name: channel_name)
          channel.add_team(team)
          channel.save
        end

        standup_days = params["standup_days"]
        StandupDay.where(team_id: team.id).delete
        if standup_days
          standup_days.each do |day|
            team.add_standup_day(name: day) unless team.day_for_standup?(day)
          end
        end

        flash.next['success'] = 'Oppdatert'
        redirect("/team/#{name}")
      end

      get '/:team_name/?' do |team_name|
        team = Team.find(Sequel.ilike(:name, team_name))
        unless team
          flash.next['error'] = "Team #{team_name} finnes ikke"
          redirect('/team/new')
        end

        standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => Date.today)
        reports = standup.nil? ? [] : standup.reports
        haml(:'standup/show', locals: {
               team: team,
               standup_date: Date.today.to_s,
               reports: reports,
               standup: standup
             }, layout: :'team/layout')
      end
    end
  end
end
