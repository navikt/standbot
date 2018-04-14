# frozen_string_literal: true

require_relative 'models/init'
require_relative 'commands/communicate'

module Standbot
  class Bot < SlackRubyBot::Bot
    SlackRubyBot::Client.logger.level = Logger::WARN
  end
end
