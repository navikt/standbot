class Standup < Sequel::Model
  def self.dates(limit=nil)
    standups = Standup.distinct(Sequel.function(:date, :created_at)).order(Sequel.desc(Sequel.function(:date, :created_at)))
    return standups if limit.nil?
    standups.limit(limit)
  end

  def self.previous(date)
    dates().where(Sequel.function(:date, :created_at) < date).first
  end

  def pretty_report
    message = ''
    message += "I går: #{yesterday}\n" if yesterday
    message += "I dag: #{today}\n" if today
    message += "Problem: #{problems}\n" if problems
    message
  end
end
