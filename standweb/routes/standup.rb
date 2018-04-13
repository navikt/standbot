# frozen_string_literal: true
module Standweb
  class Web < Sinatra::Base
    namespace '/standup/?' do
      get '/:team_name/?' do
        team_name = params['team_name']
        redirect("/standup/#{team_name}/#{Date.today}")
      end

      get '/:team_name/:date/?' do
        team_name = params['team_name']
        standup_date = params['date']
        team = Team.find(name: team_name)
        standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => standup_date)
        reports = standup.nil? ? [] : standup.reports
        haml(:'standup/show', locals: { 'team_name' => team_name, 'standup_date' => standup_date, 'reports' => reports })
      end
    end
  end
end
