# Helper access from the model
class TTHelper
  # TODO check for Singleton. seems not be used if included like this:
  # code is original from redmine_time_tracker-plugin
  include Singleton
  include TimeTrackersHelper
end

def help
  TTHelper.instance
end

class TimeTracker < ActiveRecord::Base
  unloadable

  attr_accessible :comments, :issue_id, :project_id, :start_time, :date
  attr_accessor :start_time, :date

  belongs_to :user

  # to ensure that every user can run only one tracker at one time, we have to do some validations
  validate :only_one_tracker, :on => :create

  # TODO specify all necessary validations
  # TODO add auto completion for input fields
  VALID_TIME_REGEX = /\A([01]?\d?|2[0123]):[012345]?\d?\z/ # hour:min
  VALID_DATE_REGEX = /\A\d{4}-(0?\d?|1[012])-([012]?\d?|3[01])\z/ # day:month:year
  validates :comments, length: {maximum: 150}, :allow_blank => true
  validates :project_id, :numericality => true, :allow_blank => true
  validates :issue_id, :numericality => true, :allow_blank => true
  validates :started_on, :presence => true, :unless => Proc.new { |tt| tt.new_record? }
  validates :start_time, format: {with: VALID_TIME_REGEX}, :allow_blank => true
  validates :date, format: {with: VALID_DATE_REGEX}, :allow_blank => true

  # to facilitate the user input we split up the started_on into two text fields.
  # to validate their input we set up the regex above. before saving the object to the db
  # we have to check the validations and then transfer the input data into the db-field.
  # these validations could only be called if we split up the set of the data that way.
  # so after the input, the validations were called (before saving the object) after that
  # we take the input and convert it to fit into the DateTime-format
  after_validation do
    # TODO check if user is allowed to change this entry
    # the following updates should only happen if the controller calls this method after an ui-input
    # in all other cases, the fields "start_time" and "date" might be empty
    unless self.start_time.nil? && self.date.nil?
      act_time = self.started_on.to_a
      # time
      ts = self.start_time.to_s.strip.split(':')
      act_time[1] = ts[0].to_i
      act_time[2] = ts[1].to_i
      # date
      ds = self.date.to_s.strip.split('-')
      act_time[5] = ds[0].to_i
      act_time[4] = ds[1].to_i
      act_time[3] = ds[2].to_i
      self.started_on = Time.utc(*act_time)
    end
  end

  def only_one_tracker
    errors[:base] << :time_tracker_already_running_error unless current.nil?
  end

  def initialize(arguments = nil)
    super(arguments)
    self.user_id = User.current.id
    unless issue_id.nil?
      self.project_id = issue_from_id(issue_id).project_id
    end
  end

  def start
    if self.valid?
      self.started_on = Time.now
      self.save
    end
  end

  def stop
    # due to the only_one_tracker validation we only could stop the active tracker
    if self.valid?
      # saving an TimeLog and destroying the TimeTracker have to be executed as a transaction, because we don't want to
      # track all time without any data loss.
      ActiveRecord::Base.transaction do
        time_log = TimeLog.create(:user_id => user_id, :started_on => started_on, :stopped_at => Time.now, :comments => comments)
        # if there already is a ticket-nr then we automatically associate the timeLog and the issue using a timeBooking-entry
        # and creating a time_entry
        if issue_id_set?
          issue = issue_from_id(issue_id)
          unless issue.nil?
            # project_id will be set during the add_booking method
            time_log.project_id = issue.project_id
            time_log.add_booking(:issue => issue)
          end
          # otherwise we check for a project-id and associate the timeLog with an project only, using the project_id-field
          # of the timeLog
        else
          time_log.project_id = project_id if project_id_set?
        end
        # after creating the TimeLog we can remove the TimeTracker, so the user can start a new one
        # print an error-message otherwise
        self.destroy if time_log.save
      end
    end # TODO raise an error if stop is called while self is not valid!! controller should check that too
  end

  def get_formatted_time
    self.started_on.to_time.to_s(:time) unless self.started_on.nil?
  end

  def get_formatted_date
    self.started_on.to_date.to_s(:db) unless self.started_on.nil?
  end

  # TODO method needed?
  def hours_spent
    running_time + time_spent
  end

  def time_spent_to_s
    total = hours_spent
    hours = total.to_i
    minutes = ((total - hours) * 60).to_i
    hours.to_s + l(:time_tracker_hour_sym) + minutes.to_s.rjust(2, '0')
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

  # TODO think we don't need that method neither
  def running_time
    ((Time.now.to_i - started_on.to_i) / 3600.0).to_f
  end

  protected

  def current
    TimeTracker.where(:user_id => User.current.id).first
  end

  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  def issue_id_set?
    !issue_id.nil?
  end

  def project_id_set?
    !project_id.nil?
  end

end


