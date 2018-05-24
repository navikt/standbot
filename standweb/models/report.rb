# frozen_string_literal: true

class Report < Sequel::Model
  many_to_one :member
  many_to_one :standup

  def yesterday_report
    Report.where(member_id: member.id).where(Sequel.function(:date, :created_at) => created_at.yesterday).first
  end
end
