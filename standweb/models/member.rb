# frozen_string_literal: true

class Member < Sequel::Model
  one_to_many :reports, order: Sequel.desc(:created_at)
  many_to_many :standups, join_table: :reports
  many_to_many :teams, join_table: :memberships
end
