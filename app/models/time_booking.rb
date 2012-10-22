class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id, :virtual, :project, :project_id, :issue, :comments
  belongs_to :project
  belongs_to :time_log
  belongs_to :time_entry, :dependent => :delete
  has_one :virtual_comment, :dependent => :delete

  validates_presence_of :time_log_id
  validates :time_entry_id, :presence => true, :unless => Proc.new { |tb| tb.virtual }
  validates_associated :virtual_comment, :if => Proc.new { |tb| tb.virtual }

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

  # check user-permissions. in some cass we need to prevent some or all of his actions
  before_update do
    # if the object changed and the user has not the permission to change every TimeLog (includes active trackers), we
    # have to change for special permissions in detail before saving the changes or undo them
    if self.changed?
      if (self.changed - ['comments', 'issue_id', 'project_id', 'time_entry_id']).empty?
        raise StandardError, l(:tt_error_not_allowed_to_change_booking) unless permission_level > 0
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
      super(nil)
      # without issue_id, create an virtual booking!
      if args[:issue].nil?
        # create a virtual booking
        proj = help.project_from_id(args[:project_id])
        if help.permission_checker([:tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings], proj)
          self.project = proj
          write_attribute(:project_id, proj.id)
          write_attribute(:virtual, true)
          write_attribute(:time_log_id, args[:time_log_id])
          write_attribute(:started_on, args[:started_on])
          write_attribute(:stopped_at, args[:stopped_at])
          self.save
          self.comments = args[:comments]
        else
          raise ActiveRecord::Rollback
        end
      else
        # create a normal booking
        # to enforce a user to "log time" the admin has to set the redmine permissions
        # current user could be the user himself or the admin. whoever it is, the peron needs the permission to do that
        # but in any way, the user_id which will be stored, is the user_id from the timeLog. this way the admin can book
        # times for any of his users..
        if User.current.allowed_to?(:log_time, args[:issue].project) && help.permission_checker([:tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings], args[:issue].project)
          # TODO check for user-specific setup (limitations for bookable times etc)
          time_entry = create_time_entry({:issue => args[:issue], :user_id => args[:user_id], :comments => args[:comments], :started_on => args[:started_on], :activity_id => args[:activity_id], :hours => args[:hours]})
          super({:time_entry_id => time_entry.id, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at], :project_id => args[:issue].project.id})
        else
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  # returns the hours between two timestamps
  def hours_spent(time1 = started_on, time2 = stopped_at)
    ((time2.to_i - time1.to_i) / 3600.0).to_f
  end

  def get_formatted_time(time1 = started_on, time2 = stopped_at)
    help.time_dist2string(time2.to_i - time1.to_i)
  end

  def get_formatted_start_time
    self.started_on.to_time.localtime.strftime("%H:%M:%S") unless self.started_on.nil?
  end

  def get_formatted_stop_time
    self.stopped_at.to_time.localtime.strftime("%H:%M:%S") unless self.stopped_at.nil?
  end

  # we have to redefine some setters, to ensure a convenient way to update these attributes

  def issue=(issue)
    return if issue == self.issue # no validation or permission checks necessary if there are no changes!

    user = self.user # use the user-info from the TimeLog, so the admin can change normal users entries too...
    comments = self.comments # store comments temporarily to swap them to the new place

    # we only have to do something if the issue really changes
    if issue.nil? && self.issue != l(:time_tracker_label_none) # self not virtual but new issue is nil => self became virtual
      self.time_entry.destroy

      write_attribute(:virtual, true)
      write_attribute(:comments, comments) # should create a virtual comment
    elsif !issue.nil? && issue.id != self.issue_id # issue changes => check if the user is able to change the entries on the actual project AND has the permission to book time on the new project
      if self.virtual? # self.virtual is true, than we've got a new issue due to the statement ahead. so we change from virtual to normal booking!
        self.virtual_comment.destroy
        write_attribute(:virtual, false)
      else # self not virtual? => we get a new issue, so we have to delete the old linkage
        self.time_entry.destroy
      end

      tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
      time_entry = create_time_entry({:issue => issue, :user_id => user, :comments => comments, :started_on => self.started_on, :activity_id => tea.id, :hours => self.hours_spent})

      write_attribute(:time_entry_id, time_entry.id)
      write_attribute(:project_id, issue.project.id)
    end
  end

  def project=(project)
    return if project == self.project # no validation or permission checks necessary if there are no changes!

    # only virtual bookings can choose projects. otherwise, the project will be set through the issue
    write_attribute(:project_id, nil) if self.virtual? && project.nil?
    write_attribute(:project_id, project.id) if self.virtual? && self.user.allowed_to?(:log_time, project) && self.user.allowed_to?(:tt_book_time, project)
  end

  # this method is necessary to change start and stop at the same time without leaving boundaries
  def update_time(start, stop)
    return if start == self.started_on && stop == self.stopped_at # no validation or permission checks necessary if there are no changes!

    raise StandardError, l(:error_booking_to_much_time) if start < self.time_log.started_on || start >= self.time_log.stopped_at || stop <= self.time_log.started_on || stop > self.time_log.stopped_at || start == stop

    write_attribute(:started_on, start)
    write_attribute(:stopped_at, stop)
    self.time_entry.update_attributes(:spent_on => start, :hours => self.hours_spent) unless self.virtual? #also update TimeEntry
  end

  # following methods are necessary to use the query_patch, so we can use the powerful filter options of redmine
  # to show our booking lists => which will be the base for our invoices

  def comments
    if self.virtual
      self.virtual_comment.comments
    else
      self.time_entry.comments
    end
  end

  def comments=(comments)
    if self.virtual
      vcomment = VirtualComment.where(:time_booking_id => self.id).first_or_create
      vcomment.update_attributes :comments => comments
    else
      self.time_entry.update_attributes :comments => comments
    end
  end

  def issue
    if self.time_entry.nil?
      l(:time_tracker_label_none)
    else
      self.time_entry.issue
    end
  end

  def issue_id
    if self.time_entry.nil?
      l(:time_tracker_label_none)
    else
      self.time_entry.issue.id.to_s
    end
  end

  def tt_booking_date
    self.started_on.to_date.to_s(:db)
  end

  def user
    if self.time_log.nil?
      nil
    else
      self.time_log.user
    end
  end

  private

  def create_time_entry(args ={})
    # TODO check for user-specific setup (limitations for bookable times etc)
    # create a timeBooking to combine a timeLog-entry and a timeEntry
    time_entry = args[:issue].time_entries.create({:comments => args[:comments], :spent_on => args[:started_on], :activity_id => args[:activity_id]})
    time_entry.hours = args[:hours]
    # due to the mass-assignment security, we have to set the user_id extra
    time_entry.user_id = args[:user_id]
    time_entry.save
    time_entry
  end
end
