class Standup < Sequel::Model
  many_to_one :team
  one_to_many :reports
  many_to_many :members, join_table: :reports

  def to_date
    created_at.to_date
  end

  def self.todays_reports(team_name)
    team = Team.find(name: team_name)
    return nil if team.nil?
    standup = Standup.find(:team_id => team.id, Sequel.function(:date, :created_at) => Date.today)
    Report.where(standup_id: standup.id).where(Sequel.function(:date, :created_at) => Date.today)
  end

  def self.previous(team_name, date)
    team = Team.find(name: team_name)
    return nil if team.nil?
    Standup.where(team_id: team.id).where(Sequel.function(:date, :created_at) < date).order(:created_at).last
  end

  def self.next(team_name, date)
    team = Team.find(name: team_name)
    return nil if team.nil?
    Standup.where(team_id: team.id).where(Sequel.function(:date, :created_at) > date).order(:created_at).first
  end
end
