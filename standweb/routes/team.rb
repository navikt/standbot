module Standweb
  class Web < Sinatra::Base
    namespace '/team/?' do
      get '/new/?' do
        haml(:'team/new')
      end

      post '/create/?' do
        name = params['name']
        channel_name = params['channel'].tr('#', '')
        avatar_url = params['avatar_url']
        team = Team.new(name: name)
        team.avatar_url = avatar_url unless avatar_url.empty?

        unless channel_name.empty?
          channel = Channel.find(name: channel_name)
          channel ||= Channel.create(name: channel_name)
          channel.add_team(team)
        end
        team.save

        redirect("/team/#{team.name}")
      end

      post '/:team_name/activate/?' do |team_name|
        team = Team.find(name: team_name)
        team.active = true
        team.save
        redirect("/team/#{team.name}")
      end

      post '/:team_name/deactivate/?' do |team_name|
        team = Team.find(name: team_name)
        team.active = false
        team.save
        redirect("/team/#{team.name}")
      end

      get '/:team_name/?' do
        team_name = params['team_name']
        haml(:'team/show', locals: { 'team_name' => team_name })
      end
    end
  end
end
