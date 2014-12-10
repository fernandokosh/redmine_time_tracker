require 'redmine/i18n'
class TimeBooking < ActiveRecord::Base
  include Redmine::I18n
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id, :project, :project_id
  belongs_to :project
  belongs_to :time_log
  belongs_to :time_entry, :dependent => :delete
  has_one :issue, :through => :time_entry
  has_one :activity, :through => :time_entry
  has_one :fixed_version, :through => :issue, :class_name => 'Version', :foreign_key => 'fixed_version_id'

  validates_presence_of :time_log_id
  validates :time_entry_id, :presence => true

  scope :visible, lambda {
    ca = []
    permission_list = [:tt_view_bookings, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings]
    permission_list.each { |permission|
      ca << [Project.allowed_to_condition(User.current, permission, {})]
    }
    cond = [ca.map { |c| c[0] }.join(" OR ")]

    {:include => :project,
     :conditions => cond}
  }

  scope :from_time_log, lambda { |time_log_id|
    where(time_log_id: time_log_id)
  }

  scope :overlaps_with, lambda { |start_time, stop_time|
    where(arel_table[:started_on].lt(stop_time).and(arel_table[:stopped_at].gt(start_time)))
  }

  # check user-permissions. in some cass we need to prevent some or all of his actions
  before_update do
    # if the object changed and the user has not the permission to change every TimeLog (includes active trackers), we
    # have to change for special permissions in detail before saving the changes or undo them
    if self.changed?
      if (self.changed - ['comments', 'issue', 'project_id', 'time_entry_id', 'activity_id']).empty?
        unless permission_level > 0
          raise StandardError, l(:tt_error_not_allowed_to_change_booking) if self.user == User.current
          raise StandardError, l(:tt_error_not_allowed_to_change_foreign_booking)
        end
        # want to change more than comments only? => needs more permission!
      else
        unless permission_level > 1
          raise StandardError, l(:tt_error_not_allowed_to_change_booking) if self.user == User.current
          raise StandardError, l(:tt_error_not_allowed_to_change_foreign_booking)
        end
      end
      # special checks for project-changes
      if self.changed.include?('project_id')
        old_project = Project.where(:id => self.project_id_was).first
        new_project = Project.where(:id => self.project_id).first
        # user tries to switch the time from one project to another, so we have to check his permissions on both projects before starting the update
        raise StandardError, l(:tt_error_not_allowed_to_change_booking) unless help.permission_checker([:tt_book_time, :tt_edit_bookings], old_project) && help.permission_checker([:tt_book_time, :tt_edit_bookings], new_project) ||
            self.user == User.current && User.current.allowed_to?(:tt_edit_own_bookings, old_project) && User.current.allowed_to?(:tt_edit_own_bookings, new_project)
      end
    end
  end

  after_destroy do
    self.time_log.check_bookable
  end

  def permission_level
    case
      when User.current.allowed_to?(:tt_edit_bookings, self.project) ||
          self.user == User.current && User.current.allowed_to?(:tt_edit_own_bookings, self.project)
        2
      when self.user == User.current && User.current.allowed_to?(:tt_book_time, self.project)
        1
      else
        0
    end
  end

  def initialize(args = {}, options = {})
    ActiveRecord::Base.transaction do
      proj = help.project_from_id(args[:project_id])
      raise StandardError, l(:tt_error_not_allowed_to_book_without_project) if proj.nil?
      if help.permission_checker([:tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings], proj)
        # TODO check for user-specific setup (limitations for bookable times etc)
        time_entry = create_time_entry({:project => proj, :issue => args[:issue], :user_id => args[:user_id], :comments => args[:comments], :started_on => args[:started_on], :activity_id => args[:activity_id], :hours => args[:hours]})
        super({:time_entry_id => time_entry.id, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at], :project_id => proj.id})
      else
        raise StandardError, l(:tt_error_not_allowed_to_book_on_project)
      end
    end
  end

  # returns the hours between two timestamps
  def hours_spent(time1 = started_on, time2 = stopped_at)
    ((time2.to_i - time1.to_i) / 3600.0).to_f
  end

  def get_formatted_time
    help.time_dist2string((hours_spent*60).to_i)
  end

  def get_formatted_start_time
    format_time self.started_on, false unless self.started_on.nil?
  end

  def get_formatted_stop_time
    format_time self.stopped_at, false unless self.stopped_at.nil?
  end

  # we have to redefine some setters, to ensure a convenient way to update these attributes

  def issue=(issue)
    return if issue == self.issue # no validation or permission checks necessary if there are no changes!

    # check if project has to be updated also!
    unless issue.nil?
      if issue.project != self.project
        # if the new issue is part of another project we first have to nullify the issue, change the project and than set
        # the new issue_id otherwise updating the redmine time_entry will fail
        self.time_entry.update_attributes! :issue => nil
        self.project = issue.project
      end
    end
    # workaround to get dirty-flag working even for associated fields!
    @changed_attributes['issue'] = self.issue unless issue == self.issue
    self.time_entry.update_attributes! :issue => issue #also update TimeEntry
  end

  def issue
    if self.time_entry.issue.nil?
      l(:time_tracker_label_none)
    else
      self.time_entry.issue
    end
  end

  def issue_id
    if self.time_entry.issue.nil?
      l(:time_tracker_label_none)
    else
      self.time_entry.issue.id.to_s
    end
  end

  def fixed_version
    if self.time_entry.issue.nil? || self.time_entry.issue.fixed_version.nil?
      l(:time_tracker_label_none)
    else
      self.time_entry.issue.fixed_version
    end
  end

  def project=(project)
    return if project == self.project # no validation or permission checks necessary if there are no changes!
    raise StandardError, l(:tt_error_not_allowed_to_book_without_project) if project.nil?

    # workaround to get dirty-flag working even for associated fields!
    unless project.id == self.project_id
      if self.project.nil?
        @changed_attributes['project_id'] = nil
      else
        @changed_attributes['project_id'] = self.project.id
      end
    end
    write_attribute(:project_id, project.id)
    self.time_entry.update_attributes! :project => project #also update TimeEntry
  end

  # this method is necessary to change start and stop at the same time without leaving boundaries
  def update_time(start, stop)
    return if start == self.started_on && stop == self.stopped_at # no validation or permission checks necessary if there are no changes!

    raise StandardError, l(:error_booking_to_much_time) if start < self.time_log.started_on || start >= self.time_log.stopped_at || stop <= self.time_log.started_on || stop > self.time_log.stopped_at || start == stop

    write_attribute(:started_on, start)
    write_attribute(:stopped_at, stop)
    self.time_entry.update_attributes!(:spent_on => start, :hours => self.hours_spent) #also update TimeEntry
  end

  def user_id
    self.time_entry.user_id
  end

  def activity_id
    self.time_entry.activity_id
  end

  def activity_id=(activity_id)
    # workaround to get dirty-flag working even for associated fields!
    @changed_attributes['activity_id'] = self.activity_id unless activity_id == self.activity_id
    self.time_entry.update_attributes! :activity_id => activity_id
  end

  # following methods are necessary to use the query_patch, so we can use the powerful filter options of redmine
  # to show our booking lists => which will be the base for our invoices

  def comments
    self.time_entry.comments
  end

  def comments=(comments)
    # workaround to get dirty-flag working even for associated fields!
    @changed_attributes['comments'] = self.comments unless comments == self.comments
    self.time_entry.update_attributes! :comments => comments
  end

  def tt_booking_date
    format_date(help.in_user_time_zone self.started_on) unless self.started_on.nil?
  end

  def user
    if self.time_log.nil?
      nil
    else
      self.time_log.user
    end
  end

  def virtual?
    self.time_entry.issue.nil?
  end

  private

  def create_time_entry(args ={})
    # TODO check for user-specific setup (limitations for bookable times etc)
    # create a timeBooking to combine a timeLog-entry and a timeEntry
    time_entry = TimeEntry.create({:project => args[:project], :issue => args[:issue], :hours => args[:hours], :comments => args[:comments], :spent_on => args[:started_on], :activity_id => args[:activity_id]})
    # due to the mass-assignment security, we have to set the user_id extra
    time_entry.user_id = args[:user_id]
    time_entry.save
    time_entry
  end
end
