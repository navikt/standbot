# frozen_string_literal: true

class Team < Sequel::Model
  many_to_many :members, join_table: :memberships
  one_to_many :standups
  many_to_one :channel

  def self.active
    filter(active: true)
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

  def valid_team_name
    name =~ /\A[[:word:]\-_]+\z/i
  end

  def validate
    super
    errors.add(:name, 'kan ikke være tom') if !name || name.empty?
    errors.add(name, 'er ikke et godkjent team navn (regex: /\A[[:word:]-_]+\z/i)') unless valid_team_name
  end
end
