# frozen_string_literal: true

class Team < Sequel::Model
  TEAM_NAME_REGEX = Regexp.new("\\A[[:word:]\-]+\\z", Regexp::IGNORECASE)

  many_to_many :members, join_table: :memberships, order: :full_name
  one_to_many :standups
  many_to_one :channel

  def self.active
    filter(active: true).order(:name)
  end

  def members_name
    members.map(&:full_name)
  end

  def standups
    Standup.where(team_id: id).order(Sequel.desc(:created_at))
  end

  def avatar
    avatar_url.to_s.empty? ? '/images/dummy-profile-pic.png' : avatar_url
  end

  def todays_standup
    Standup.where(team_id: id, Sequel.function(:date, :created_at) => Date.today).first
  end

  def time_for_standup?(time)
    standup_time == time
  end

  def time_for_reminder?(time)
    reminder && standup_time == (time.to_i - 30)
  end

  def time_for_summary?(time)
    summary && channel && standup_time == (time.to_i - 100)
  end

  def valid_team_name?
    name =~ TEAM_NAME_REGEX
  end

  def valid_standup_time?
    ['0900', '0930', '1000'].include?(standup_time)
  end

  def validate
    super
    errors.add('Team navn', 'kan ikke være tom') if !name || name.empty?
    errors.add('Team navn', "er ikke et godkjent team navn (regex: #{TEAM_NAME_REGEX}") unless valid_team_name?
    errors.add('Standup-up klokkeslett', 'kan ikke være tom') if !standup_time || standup_time.empty?
    errors.add('Standup-up klokkeslett', 'må være en av følgende tider: 0900, 0930, 1000') unless valid_standup_time?
  end
end
