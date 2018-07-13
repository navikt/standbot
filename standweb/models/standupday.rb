class StandupDay < Sequel::Model
  many_to_one :team
end
