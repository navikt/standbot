$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'dotenv/load' unless ENV['RACK_ENV'] == 'production'

require 'slack-ruby-bot'
require 'sinatra'

require 'standbot/commands/communicate'
require 'standbot/bot'
require 'standbot/models/init'
require 'standbot/routes/init'

Thread.abort_on_exception = true

Thread.new do
  begin
    Standbot::Bot.run
  rescue Exception => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

run Standbot::StandWeb.new
