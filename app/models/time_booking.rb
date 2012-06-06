class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id
  belongs_to :time_log
  belongs_to :time_entry

  validates_presence_of :time_log_id, :time_entry_id

  def initialize(arguments = nil, *args)
    super(arguments)
  end

  def self.get_bookings(user = User.current)
    tl_id = user.time_logs.pluck(:id)
    where(:time_log_id => tl_id).all
  end

  def hours_spent
    ((stopped_at.to_i - started_on.to_i) / 3600.0).to_f
  end
end
