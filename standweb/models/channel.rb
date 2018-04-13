# frozen_string_literal: true
class Channel < Sequel::Model
  one_to_many :team
end
