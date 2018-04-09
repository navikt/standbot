$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'dotenv/load' unless ENV['RACK_ENV'] == 'production'

require 'slack-ruby-bot'

require 'standbot/bot'
require 'standweb/web'

Thread.abort_on_exception = true

Thread.new do
  begin
    Standbot::Bot.run
  rescue StandardError => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

run Standweb::Web.new
