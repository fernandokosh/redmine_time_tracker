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

  attr_accessible :comments, :issue_id, :project_id

  belongs_to :user

  # to ensure that every user can run only one tracker at one time, we have to do some validations
  validate :only_one_tracker, :on => :create

  def only_one_tracker
    errors[:base] << :time_tracker_already_running_error unless current.nil?
  end

  def initialize(arguments = nil)
    super(arguments)
    self.user_id = User.current.id
    self.started_on = Time.now
    unless issue_id.nil?
      self.project_id = issue_from_id(issue_id).project_id
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
          # project_id will be set during the add_booking method
          time_log.project_id = issue.project_id
          time_log.add_booking(:issue => issue)
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


