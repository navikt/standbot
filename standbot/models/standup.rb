class Standup < Sequel::Model
  many_to_one :team
  one_to_many :reports
  many_to_many :members, join_table: :reports
end
