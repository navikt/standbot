# frozen_string_literal: true
module Standweb
  class Web < Sinatra::Base
    namespace '/members/?' do
      get '/:team_name/add/?' do
        team_name = params['team_name']
        team = Team.find(name: team_name)
        client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
        members = client.users_list.members.reject(&:deleted)
        members.reject! { |member| team.members_name.include?(member.profile.real_name) }
        haml(:'members/add', locals: { 'team_name' => team_name, 'members' => members })
      end

      post '/:team_name/add/?' do
        team_name = params['team_name']
        team = Team.find(name: team_name)
        slack_id = params['id']
        member = Member.find(slack_id: slack_id)
        redirect("/#{team_name}") if member && team.members.include?(member)

        if member
          team.add_member(member)
        else
          client = ::Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
          user = client.users_info(user: slack_id).user
          team.add_member(slack_id: slack_id, full_name: user.profile.real_name, avatar_url: user.profile.image_72)
        end
        redirect("/#{team_name}")
      end

      post '/:team_name/remove/?' do
        team_name = params['team_name']
        member_id = params['id']
        team = Team.find(name: team_name)
        team.remove_member(member_id)
        redirect("/#{team_name}")
      end
    end
  end
end
