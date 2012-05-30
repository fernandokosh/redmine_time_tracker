class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id
  belongs_to :time_log
  belongs_to :time_entry

  validates_presence_of :time_log_id, :time_entry_id

  def initialize(arguments = nil, *args)
    super(arguments)
  end
end
