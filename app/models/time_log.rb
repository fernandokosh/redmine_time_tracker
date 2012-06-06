class TimeLog < ActiveRecord::Base
  unloadable

  attr_accessible :user_id, :started_on, :stopped_at, :project_id, :comments
  # using the virtual-flag for objects that should never been saved to the database
  attr_accessor :virtual
  belongs_to :user
  has_many :time_bookings
  has_many :time_entries, :through => :time_bookings

  validate :save_no_virtuals, :on => :create

  def save_no_virtuals
    errors[:base] << "never save virtuals" if current.virtual.true?
  end

  #def initialize(arguments = nil, *args)
  def initialize(arguments = nil, args = {})
    super(arguments)
    if args[:virtual].nil?
      self.virtual = false
    else
      self.virtual = args[:virtual]
    end
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

  # this method finds all partially or entirely not booked time_logs
  def self.get_partial_booked_logs(user = User.current)
    logs = []
    user.time_logs.each do |tl|
      if tl.time_bookings.empty?
        # log was not booked at all
        logs.push(tl)
      else
        # every gap between the bookings should be bookable so we create virtual logs for them to show them in the list
        temp = nil
        tl.time_bookings.order('started_on ASC').each do |tb|
          if temp.nil?
            temp = tb
          else
            if tb.started_on > temp.stopped_at
              logs.push(TimeLog.new({:id => tl.id, :user_id => tl.user_id, :started_on => temp.stopped_at, :stopped_at => tb.started_on}, :virtual => true))
            end
            temp = tb
          end
        end
        logs.push(TimeLog.new({:id => tl.id, :user_id => tl.user_id, :started_on => temp.stopped_at, :stopped_at => tl.stopped_at}, :virtual => true)) if temp.stopped_at < tl.stopped_at
      end
    end
    logs
  end

  # deprecated due to get_partial_booked_logs will also return unbooked logs
  #def self.get_unbooked_logs(user = User.current)
  #  # for now we only get the time_logs which have no booking associated.
  #  user.time_logs.where("id not in (select time_log_id from time_bookings)").all
  #  # TODO implement full functionality to get_unbooked_logs
  #  # what we want are all logs which have some of their time unbooked
  #end
end
