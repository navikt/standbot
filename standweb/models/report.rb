class Report < Sequel::Model
  many_to_one :member
  many_to_one :standup
end