# frozen_string_literal: true
module Standweb
  class Web < Sinatra::Base
    namespace '/team/?' do
      get '/new/?' do
        haml(:'team/new')
      end

      post '/create/?' do
        name = params['name'].strip
        if Team.find(Sequel.ilike(:name, name))
          flash.next['error'] = 'Team navn eksisterer'
          redirect("/team/new")
        end

        if name.empty?
          flash.next['error'] = 'Team navn kan ikke være blank'
          redirect("/team/new")
        end

        channel_name = params['channel'].strip.tr('#', '')
        description = params['description'].strip
        avatar_url = params['avatar_url'].strip
        team = Team.new(name: name)
        team.description = description unless description.empty?
        team.avatar_url = avatar_url unless avatar_url.empty?

        unless channel_name.empty?
          channel = Channel.find(name: channel_name)
          channel ||= Channel.create(name: channel_name)
          channel.add_team(team)
        end

        unless team.valid?
          flash.next['error'] = team.errors.full_messages.join('\n')
          redirect("/team/new")
        end
        team.save

        redirect("/team/#{team.name}")
      end

      post '/:team_name/activate/?' do |team_name|
        team = Team.find(name: team_name)
        team.active = true
        team.save
        flash.next['success'] = 'Team er reaktivert'
        redirect("/team/#{team.name}")
      end

      post '/:team_name/deactivate/?' do |team_name|
        team = Team.find(name: team_name)
        team.active = false
        team.save
        flash.next['success'] = 'Team er deaktivert'
        redirect("/team/#{team.name}")
      end

      get '/:team_name/?' do
        team_name = params['team_name']
        haml(:'team/show', locals: { 'team_name' => team_name })
      end
    end
  end
end
