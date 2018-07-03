# frozen_string_literal: true

class Member < Sequel::Model
  one_to_many :reports, order: Sequel.desc(:created_at)
  many_to_many :standups, join_table: :reports
  many_to_many :teams, join_table: :memberships

  def vacation?
    return false if member.vacation_to.nil?
    (member.vacation_from...(member.vacation_to + 1)).include?(Date.today)
  end
end
