module Standbot
  class Bot < SlackRubyBot::Bot
    SlackRubyBot::Client.logger.level = Logger::WARN
  end
end
