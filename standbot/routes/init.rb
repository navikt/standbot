module Standbot
  class StandWeb < Sinatra::Application
    configure :production do
      set :clean_trace, true
      enable :logging
    end

    configure :development do
      enable :logging
    end
  end
end

require_relative 'api'
require_relative 'healthchecks'
require_relative 'web'
