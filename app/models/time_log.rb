require 'redmine/i18n'
class TimeLog < ActiveRecord::Base
  include Redmine::I18n

  attr_accessible :user_id, :started_on, :stopped_at, :project_id, :comments, :issue_id, :spent_time, :bookable
  attr_accessor :issue_id, :spent_time
  belongs_to :user
  has_many :time_bookings, :dependent => :delete_all
  has_many :time_entries, :through => :time_bookings

  # prevent that updating the time_log results in negative bookable_time
  validate :check_time_spent, :on => :update
  validates :comments, :length => {:maximum => 255}, :allow_blank => true
  validates :user_id, :presence => true
  validates :started_on, :presence => true
  validates :stopped_at, :presence => true

  scope :bookable, -> { where(:bookable => true) }

  scope :visible, lambda {
    if help.permission_checker([:tt_edit_time_logs], {}, true)
      where("1 = 1")
    elsif help.permission_checker([:tt_log_time, :tt_edit_own_time_logs, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings], {}, true)
      where(:user_id => User.current.id)
    else
      where("1 = 0")
    end
  }

  scope :from_current_user, lambda {
    where arel_table[:user_id].eq User.current.id
  }

  # we have to check user-permissions. i some cass we have to forbid some or all of his actions
  before_update do
    # if the object changed and the user has not the permission to change every TimeLog (includes active trackers), we
    # have to change for special permissions in detail before saving the changes or undo them
    if self.changed? && !User.current.allowed_to_globally?(:tt_edit_time_logs, {})
      # changing the comments only could be allowed
      if self.changed == ['comments']
        unless permission_level > 0
          raise StandardError, l(:tt_error_not_allowed_to_change_logs) if self.user.id == User.current.id
          raise StandardError, l(:tt_error_not_allowed_to_change_foreign_logs)
        end
      elsif (self.changed - ['comments', 'issue_id', 'project_id']).empty?
        unless permission_level > 1
          raise StandardError, l(:tt_error_not_allowed_to_change_logs) if self.user.id == User.current.id
          raise StandardError, l(:tt_error_not_allowed_to_change_foreign_logs)
        end
        # want to change more than comments only? => needs more permission!
      else
        unless permission_level > 2
          raise StandardError, l(:tt_error_not_allowed_to_change_logs) if self.user.id == User.current.id
          raise StandardError, l(:tt_error_not_allowed_to_change_foreign_logs)
        end
      end
    end
  end

  def permission_level
    case
      when User.current.allowed_to_globally?(:tt_edit_time_logs, {}) ||
          self.user == User.current && User.current.allowed_to_globally?(:tt_edit_own_time_logs, {})
        3
      when User.current.allowed_to_globally?(:tt_edit_bookings, {}) ||
          self.user == User.current && help.permission_checker([:tt_book_time, :tt_edit_own_bookings], {}, true)
        2
      when self.user == User.current && User.current.allowed_to_globally?(:tt_log_time, {})
        1
      else
        0
    end
  end

  after_save do
    # we have to keep the "bookable"-flag up-to-date
    # update_column saves the value without running any callbacks or validations! this is  necessary here because
    # bookable is a flag which should only be stored in DB to make faster DB-searches possible. so every time something
    # changes on this object, this flag has to be checked!!
    self.reload
    update_column(:bookable, bookable_hours > 0) if self.bookable != (bookable_hours > 0)
  end

  def check_time_spent
    raise StandardError, l(:tt_update_log_results_in_negative_time) if self.bookable_hours < 0
  end

  def initialize(arguments = nil, *args)
    super(arguments)
  end

  # if issue is the only parameter we get, we will book the whole time to one issue
  # method returns the booking.id if transaction was successfully completed, raises an error otherwise
  def add_booking(args = {})
    default_args = {:started_on => self.started_on, :stopped_at => self.stopped_at, :comments => self.comments, :activity_id => args[:activity_id], :issue => nil, :spent_time => nil, :project_id => self.project_id}
    args = default_args.merge(args)

    # TODO check time boundaries
    args[:started_on] = help.build_timeobj_from_strings help.parse_localised_date_string(tt_log_date), help.parse_localised_time_string(args[:start_time]) if args[:start_time].is_a? String
    args[:stopped_at] = help.build_timeobj_from_strings help.parse_localised_date_string(tt_log_date), help.parse_localised_time_string(args[:stop_time]) if args[:stop_time].is_a? String

    # basic calculations are always the same
    args[:spent_time].nil? ? args[:hours] = hours_spent(args[:started_on], args[:stopped_at]) : args[:hours] = help.time_string2hour(args[:spent_time])
    args[:stopped_at] = args[:started_on] + args[:hours].hours

    raise StandardError, l(:error_booking_negative_time) if args[:hours] <= 0
    raise StandardError, l(:error_booking_to_much_time) if args[:hours] > bookable_hours
    raise StandardError, l(:error_booking_overlapping) if TimeBooking.from_time_log(self.id).overlaps_with(args[:started_on], args[:stopped_at]).exists?

    args[:time_log_id] = self.id
    # userid of booking will be set to the user who created timeLog, even if the admin will create the booking
    args[:user_id] = self.user_id
    tb = TimeBooking.create(args)
    # tb.persisted? will be true if transaction was successfully completed
    if tb.persisted?
      update_column(:bookable, (bookable_hours - tb.hours_spent > 0))
      tb.id # return the booking id to get the last added booking
    else
      raise StandardError, l(:error_add_booking_failed)
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
    help.time_dist2string((bookable_hours*60).to_i)
  end

  def get_formatted_time_span
    help.time_dist2string((hours_spent*60).to_i)
  end

  def get_formatted_booked_time
    help.time_dist2string((hours_booked*60).to_i)
  end

  def get_formatted_start_time
    format_time self.started_on, false unless self.started_on.nil?
  end

  def get_formatted_stop_time
    format_time self.stopped_at, false unless self.stopped_at.nil?
  end

  def tt_log_date
    format_date(help.in_user_time_zone self.started_on) unless self.started_on.nil?
  end

  def tt_log_stop_date
    format_date(help.in_user_time_zone self.stopped_at) unless self.stopped_at.nil?
  end

  # returns the sum of bookable time of an time entry
  # if log was not booked at all, so the whole time is bookable
  def bookable_hours
    # every gap between the bookings represents bookable time so we sum up the time to show it as bookable time
    hours_spent - hours_booked
  end

  def check_bookable
    update_column(:bookable, bookable_hours > 0)
  end
end
