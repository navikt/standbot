module Standbot
  class StandWeb < Sinatra::Application
    get '/isReady' do
      'OK'
    end

    get '/isAlive' do
      'OK'
    end
  end
end
