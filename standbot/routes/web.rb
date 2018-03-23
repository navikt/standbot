require 'date'

module Standbot
  class StandWeb < Sinatra::Application
    get '/' do
      haml(:index)
    end

    get '/standup/:date/?' do
      standup_date = params['date']
      haml(:reports, locals: { 'reports' => Standup.where(Sequel.function(:date, :created_at) => standup_date).order(:created_at),
                               'standup_date' => standup_date })
    end

    get '/standups/?' do
      redirect "/standup/#{Date.today}"
    end
  end
end
