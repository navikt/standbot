# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/json'
require 'sinatra/namespace'
require 'google/cloud/error_reporting'

module Standweb
  class Web < Sinatra::Base
    use(Google::Cloud::ErrorReporting::Middleware) if ENV['RACK_ENV'] == 'production'
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
require_relative 'services/init'
require_relative 'routes/init'
