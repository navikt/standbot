class Membership < Sequel::Model
  many_to_one :team
  many_to_one :member
end
