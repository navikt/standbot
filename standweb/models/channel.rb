class Channel < Sequel::Model
  one_to_many :team
end
