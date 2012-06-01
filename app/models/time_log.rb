class TimeLog < ActiveRecord::Base
  unloadable

  attr_accessible :user_id, :started_on, :stopped_at, :project_id, :comments
  belongs_to :user
  has_many :time_bookings
  has_many :time_entries, :through => :time_bookings

  def initialize(arguments = nil, *args)
    super(arguments)
  end

  # if issue is the only parameter we get, we will book the whole time to one issue
  def add_booking(issue)
    # TODO check for user-specific setup (limitations for bookable times etc)
    # TODO ensure that the sum of all time-bookings does not break the whole time of a timeLog
    # create a timeBooking to combine a timeLog-entry and a timeEntry
    ActiveRecord::Base.transaction do
      time_entry = issue.time_entries.create(:comments => comments, :spent_on => Time.now, :hours => hours_spent, :activity_id => 1)
      # due to the mass-assignment security, we have to set the user_id extra
      time_entry.user_id = user_id
      time_entry.save
      TimeBooking.create(:time_entry_id => time_entry.id, :time_log_id => id, :started_on => started_on, :stopped_at => stopped_at)
    end
  end

  def hours_spent
    ((stopped_at.to_i - started_on.to_i) / 3600.0).to_f
  end
end
