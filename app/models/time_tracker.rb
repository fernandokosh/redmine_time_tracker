class TimeTracker < ActiveRecord::Base
  unloadable

  attr_accessible :comments, :issue_id, :project_id, :start_time, :date, :round
  attr_accessor :start_time, :date

  belongs_to :user

  # to ensure that every user can run only one tracker at one time, we have to do some validations
  validate :only_one_tracker, :on => :create

  # TODO specify all necessary validations
  # TODO add auto completion for input fields
  VALID_TIME_REGEX = /\A([01]?\d?|2[0123]):[012345]?\d?:?[012345]?\d?\z/ # hour:min[:sec]
  VALID_DATE_REGEX = /\A\d{4}-(0?\d?|1[012])-([012]?\d?|3[01])\z/ # year:month:day
  validates :comments, :length => {:maximum => 255}, :allow_blank => true
  validates :project_id, :numericality => true, :allow_blank => true
  validates :issue_id, :numericality => true, :allow_blank => true
  validates :started_on, :presence => true, :unless => Proc.new { |tt| tt.new_record? }
  validates :start_time, :format => {:with => VALID_TIME_REGEX}, :allow_blank => true
  validates :date, :format => {:with => VALID_DATE_REGEX}, :allow_blank => true

  # to facilitate the user input we split up the started_on into two text fields.
  # to validate their input we set up the regex above. before saving the object to the db
  # we have to check the validations and then transfer the input data into the db-field.
  # these validations could only be called if we split up the set of the data that way.
  # so after the input, the validations were called (before saving the object) after that
  # we take the input and convert it to fit into the DateTime-format
  after_validation do
    # the following updates should only happen if the controller calls this method after an ui-input
    # in all other cases, the fields "start_time" and "date" might be empty
    unless self.start_time.nil? && self.date.nil?
      self.started_on = Time.parse(self.date.to_s + " " + self.start_time.to_s)
    end
  end

  before_save do
    issue = help.issue_from_id(self.issue_id)
    if issue.nil?
      self.issue_id = self.issue_id_was unless self.issue_id.blank?
    else
      self.project_id = issue.project_id unless issue.nil? || self.project_id == issue.project_id
    end
  end

  # check user-permissions. in some cass we need to prevent some or all of his actions
  before_update do
    # if the object changed and the user has not the permission to change every TimeLog (includes active trackers), we
    # have to change for special permissions in detail before saving the changes or undo them
    if self.changed?
      # changing the comments only could be allowed
      if (self.changed - ['comments', 'round']).empty?
        raise StandardError, l(:tt_error_not_allowed_to_change_logs) unless permission_level > 0
      elsif (self.changed - ['comments', 'round', 'issue_id', 'project_id']).empty?
        raise StandardError, l(:tt_error_not_allowed_to_change_logs) unless permission_level > 1
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
          self.user.id == User.current.id && User.current.allowed_to_globally?(:tt_edit_own_time_logs, {})
        3
      when User.current.allowed_to_globally?(:tt_edit_bookings, {}) ||
          self.user.id == User.current.id && help.permission_checker([:tt_book_time, :tt_edit_own_bookings], {}, true)
        2
      when self.user.id == User.current.id && User.current.allowed_to_globally?(:tt_log_time, {})
        1
      else
        0
    end
  end

  def only_one_tracker
    raise StandardError, l(:time_tracker_already_running_error) unless current.nil?
  end

  def initialize(arguments = nil)
    unless arguments.nil?
      issue = help.issue_from_id(arguments[:issue_id])
      arguments[:issue_id] = nil if issue.nil?
    end
    super(arguments)
    self.user_id = User.current.id
    unless issue.nil?
      self.project_id = issue.project_id
    end
    raise StandardError, l(:tt_error_not_allowed_to_create_time_log) if permission_level < 1
  end

  def start
    if self.valid?
      self.started_on = Time.now.localtime.change(:sec => 0)
      self.save
    end
  end

  def stop
    # due to the only_one_tracker validation we only could stop the active tracker
    if self.valid?
      # saving an TimeLog and destroying the TimeTracker have to be executed as a transaction, because we don't want to
      # track all time without any data loss.
      ActiveRecord::Base.transaction do
        stop_time = Time.now.localtime.change(:sec => 0) + 1.minute
        if self.round # round times to solid quarters of an hour
          t_diff = (stop_time.to_i - started_on.to_i)
          unless (t_diff % 900) == 0
            stop_time = started_on + (t_diff / 900 + 1) * 900
          end
        end
        time_log = TimeLog.create(:user_id => user_id, :started_on => started_on, :stopped_at => stop_time, :comments => comments)
        # if there already is a ticket-nr then we automatically associate the timeLog and the issue using a timeBooking-entry
        # and creating a time_entry
        issue = help.issue_from_id(issue_id)
        time_log.add_booking({:project_id => project_id, :issue => issue}) unless issue.nil? && project_id.nil?
        # after creating the TimeLog we can remove the TimeTracker, so the user can start a new one
        # print an error-message otherwise
        self.destroy if time_log.save
      end
    end # TODO raise an error if stop is called while self is not valid!! controller should check that too
  end

  def get_formatted_time
    self.started_on.to_time.localtime.strftime("%H:%M:%S") unless self.started_on.nil?
  end

  def get_formatted_date
    self.started_on.to_date.to_s(:db) unless self.started_on.nil?
  end

  def zombie?
    user = help.user_from_id(self.user_id)
    if user.nil? or user.locked?
      return true
    end

    issue = help.issue_from_id(issue_id)
    unless issue.nil?
      return true unless user.allowed_to?(:log_time, issue.project)
    end

    false
  end

  def running_time
    Time.now.localtime.to_i - started_on.to_i
  end

  protected

  def current
    TimeTracker.where(:user_id => User.current.id).first
  end
end
