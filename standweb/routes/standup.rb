# frozen_string_literal: true

module Standweb
  class Web < Sinatra::Base
    namespace '/standups/?' do
      get '/:team_name/?' do |team_name|
        team = Team.find(name: team_name)
        haml(:'standup/index', locals: { team: team }, layout: :'team/layout')
      end

      get '/:team_name/:standup_date/?' do |team_name, standup_date|
        team = Team.find(name: team_name)
        standup = Standup.find(team_id: team.id, Sequel.function(:date, :created_at) => standup_date)
        reports = standup.nil? ? [] : standup.reports
        haml(:'standup/show', locals: { team: team, standup_date: standup_date, reports: reports }, layout: :'team/layout')
      end
    end
  end
end
