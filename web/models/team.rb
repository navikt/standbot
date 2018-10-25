# frozen_string_literal: true

class Team < Sequel::Model
  TEAM_NAME_REGEX = Regexp.new("\\A[[:word:]\-]+\\z", Regexp::IGNORECASE)
  THIRTY_MINUTES = 30 * 60
  ONE_HOUR = 1 * 60 * 60
  STANDUP_TIMES = ['09:00', '09:30', '10:00', '14:30'].freeze

  many_to_many :members, join_table: :memberships, order: :full_name
  one_to_many :standups
  many_to_one :channel
  one_to_many :standup_days

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

  def day_for_standup?(day)
    StandupDay.find(team_id: id, name: day) != nil
  end

  def time_for_standup?(time)
    standup_time == time
  end

  def time_for_reminder?(time)
    reminder && Time.parse(standup_time) == (Time.parse(time) - THIRTY_MINUTES)
  end

  def time_for_summary?(time)
    summary && channel && Time.parse(standup_time) == (Time.parse(time) - ONE_HOUR)
  end

  def valid_team_name?
    name =~ TEAM_NAME_REGEX
  end

  def valid_standup_time?
    STANDUP_TIMES.include?(standup_time)
  end

  def validate
    super
    errors.add('Team navn', 'kan ikke være tom') if !name || name.empty?
    errors.add('Team navn', "er ikke et godkjent team navn (regex: #{TEAM_NAME_REGEX}") unless valid_team_name?
    errors.add('Standup-up klokkeslett', 'kan ikke være tom') if !standup_time || standup_time.empty?
    errors.add('Standup-up klokkeslett', "må være en av følgende tider: #{STANDUP_TIMES.join(',')}") unless valid_standup_time?
  end
end
