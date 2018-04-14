# frozen_string_literal: true

class Membership < Sequel::Model
  one_to_one :team
  one_to_one :member
end
