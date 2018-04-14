# frozen_string_literal: true

require 'spec_helper'

describe Standbot::Bot do
  def app
    Standbot::Bot.instance
  end

  subject { app }

  it_behaves_like 'a slack ruby bot'
end
