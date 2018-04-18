# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/namespace'

module Standweb
  class Web < Sinatra::Base
    enable(:logging)
    enable(:sessions)
    register(Sinatra::Flash)

    configure :production do
      set(:clean_trace, true)
      set(:logging, Logger::INFO)
    end

    configure :development do
      set(:logging, Logger::DEBUG)
    end

    get '/' do
      haml(:index)
    end
  end
end

require_relative 'models/init'
require_relative 'routes/init'
