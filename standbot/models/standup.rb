class Standup < Sequel::Model
  # plugin :validation_helpers

  # def validate
  #   validates_presence [:name, :year]
  #   validates_includes 1..10, :rating
  #   if genre == "Horror"
  #     validates_presence :rated
  #   end
  # end

  def pretty_report
    message = ''
    message += "I går: #{yesterday}\n" if yesterday
    message += "I dag: #{today}\n" if today
    message += "Problem: #{problems}\n" if problems
    message
  end
end
