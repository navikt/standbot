$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'dotenv/load' unless ENV['RACK_ENV'] == 'production'

require 'slack-ruby-bot'

require 'standweb/web'

run Standweb::Web.new
