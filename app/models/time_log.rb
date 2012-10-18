class TimeLogError < StandardError
  attr_reader :message

  def initialize(message)
    @message = message
  end
end

class TimeLog < ActiveRecord::Base
  unloadable

  attr_accessible :user_id, :started_on, :stopped_at, :project_id, :comments, :issue_id, :spent_time, :bookable
  attr_accessor :issue_id, :spent_time
  belongs_to :user
  has_many :time_bookings, :dependent => :delete_all
  has_many :time_entries, :through => :time_bookings

  # prevent that updating the time_log results in negative bookable_time
  validate :check_time_spent, :on => :update
  validates :comments, :length => {:maximum => 255}, :allow_blank => true

  scope :bookable, where(:bookable => true)

  after_save do
    # we have to keep the "bookable"-flag up-to-date
    update_attribute(:bookable, bookable_hours > 0) if self.bookable != (bookable_hours > 0)
  end

  def check_time_spent
    raise TimeLogError, l(:tt_update_log_results_in_negative_time) if self.bookable_hours < 0
  end

  def initialize(arguments = nil, *args)
    super(arguments)
  end

  # if issue is the only parameter we get, we will book the whole time to one issue
  # method returns the booking.id if transaction was successfully completed, raises an error otherwise
  def add_booking(args = {})
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    default_args = {:started_on => self.started_on, :stopped_at => self.stopped_at, :comments => self.comments, :activity_id => tea.id, :issue => nil, :spent_time => nil, :virtual => false, :project_id => self.project_id}
    args = default_args.merge(args)

    # TODO check time boundaries
    args[:started_on] = Time.parse(tt_log_date + " " + args[:start_time]) if args[:start_time].is_a? String
    args[:stopped_at] = Time.parse(tt_log_date + " " + args[:stop_time]) if args[:stop_time].is_a? String

    # basic calculations are always the same
    args[:spent_time].nil? ? args[:hours] = hours_spent(args[:started_on], args[:stopped_at]) : args[:hours] = help.time_string2hour(args[:spent_time])
    args[:stopped_at] = Time.at(args[:started_on].to_i + (args[:hours] * 3600).to_i).getlocal

    raise TimeLogError, l(:error_booking_negative_time) if args[:hours] <= 0
    raise TimeLogError, l(:error_booking_to_much_time) if args[:hours] > bookable_hours

    args[:time_log_id] = self.id
    # userid of booking will be set to the user who created timeLog, even if the admin will create the booking
    args[:user_id] = self.user_id
    tb = TimeBooking.create(args)
    # tb.persisted? will be true if transaction was successfully completed
    if tb.persisted?
      update_attribute(:bookable, (bookable_hours - tb.hours_spent > 0))
      tb.id # return the booking id to get the last added booking
    else
      raise TimeLogError, l(:error_add_booking_failed)
    end
  end

  # returns the hours between two timestamps
  def hours_spent(time1 = started_on, time2 = stopped_at)
    ((time2.to_i - time1.to_i) / 3600.0).to_f
  end

  def hours_booked
    time_booked = 0
    time_bookings.each do |tb|
      time_booked += tb.hours_spent
    end
    time_booked
  end

  def get_formatted_bookable_hours
    help.time_dist2string((bookable_hours*3600).to_i)
  end

  def get_formatted_time_span
    help.time_dist2string((hours_spent*3600).to_i)
  end

  def get_formatted_booked_time
    help.time_dist2string((hours_booked*3600).to_i)
  end

  def get_formatted_start_time
    self.started_on.to_time.localtime.strftime("%H:%M:%S") unless self.started_on.nil?
  end

  def get_formatted_stop_time
    self.stopped_at.to_time.localtime.strftime("%H:%M:%S") unless self.stopped_at.nil?
  end

  def tt_log_date
    self.started_on.to_date.to_s(:db)
  end

  # returns the sum of bookable time of an time entry
  # if log was not booked at all, so the whole time is bookable
  def bookable_hours
    # every gap between the bookings represents bookable time so we sum up the time to show it as bookable time
    hours_spent - hours_booked
  end

  def check_bookable
    update_attribute(:bookable, bookable_hours > 0)
  end
end
