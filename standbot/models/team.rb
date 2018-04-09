class Team < Sequel::Model
  many_to_many :members, join_table: :memberships
  one_to_many :standups
  many_to_one :channel

  def self.active
    Team.where(active: true).all
  end

  def members_name
    members.map(&:full_name)
  end
end
