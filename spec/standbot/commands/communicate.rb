require 'spec_helper'

describe Standbot::Commands::Communicate do
  def app
    Standbot::Bot.instance
  end

  subject { app }

  it 'returns pong' do
    expect(message: "#{SlackRubyBot.config.user} ping", channel: 'channel').to respond_with_slack_message('pong')
  end
end
