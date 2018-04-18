# frozen_string_literal: true

module Standweb
  class Web < Sinatra::Base
    namespace '/team/?' do
      get '/new/?' do
        haml(:'team/new')
      end

      post '/create/?' do
        name = params['name'].strip
        if name.empty?
          flash.next['error'] = 'Team navn kan ikke være blank'
          redirect('/team/new')
        end

        if Team.find(Sequel.ilike(:name, name))
          flash.next['error'] = 'Team navn eksisterer'
          redirect('/team/new')
        end

        team = Team.new(name: name)
        team.avatar_url = params['avatar_url'].strip

        unless team.valid?
          flash.next['error'] = team.errors.full_messages.join('\n')
          redirect('/team/new')
        end
        team.save

        redirect("/members/#{team.name}/add")
      end

      post '/:team_name/activate/?' do |team_name|
        team = Team.find(name: team_name)
        unless team
          flash.next['error'] = 'Team finnes ikke'
          redirect('/team/new')
        end

        team.active = true
        team.save
        redirect("/team/#{team.name}")
      end

      post '/:team_name/deactivate/?' do |team_name|
        team = Team.find(name: team_name)
        unless team
          flash.next['error'] = 'Team finnes ikke'
          redirect('/team/new')
        end

        team.active = false
        team.save
        redirect("/team/#{team.name}")
      end

      get '/:team_name/edit/?' do |team_name|
        team = Team.find(Sequel.ilike(:name, team_name))
        unless team
          flash.next['error'] = "Team #{team_name} finnes ikke"
          redirect('/team/new')
        end

        haml(:'team/edit', locals: { team: team }, layout: :'team/layout')
      end

      post '/:team_name/update' do |team_name|
        name = params['name'].strip
        if name.empty?
          flash.next['error'] = 'Team navn kan ikke være blank'
          redirect("/team/#{team_name}/edit")
        end

        team = Team.find(Sequel.ilike(:name, name))
        if team && name != team_name
          flash.next['error'] = "Team #{team_name} finnes fra før av"
          redirect("/team/#{team_name}/edit")
        end

        team.avatar_url = params['avatar_url'].strip

        unless team.valid?
          flash.next['error'] = team.errors.full_messages.join('\n')
          redirect("/team/#{team_name}/edit")
        end
        team.save

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
        haml(:'team/show', locals: { team: team, reports: reports }, layout: :'team/layout')
      end
    end
  end
end
