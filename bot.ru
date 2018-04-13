# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'dotenv/load' unless ENV['RACK_ENV'] == 'production'

require 'slack-ruby-bot'

require 'standbot/bot'

Standbot::Bot.run
