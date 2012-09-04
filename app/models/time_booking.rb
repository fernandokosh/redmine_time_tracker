class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id, :virtual, :project, :project_id
  belongs_to :project
  belongs_to :time_log
  belongs_to :time_entry, :dependent => :delete
  has_one :virtual_comment, :dependent => :delete

  validates_presence_of :time_log_id
  validates :time_entry_id, :presence => true, :unless => Proc.new { |tb| tb.virtual }
  validates_associated :virtual_comment, :if => Proc.new { |tb| tb.virtual }

  # scope :last_two_weeks, where("started_on > ? ", (Time.now-2.weeks).beginning_of_day)

  def initialize(args = {}, options = {})
    ActiveRecord::Base.transaction do
      super(nil)
      self.save
      # without issue_id, create an virtual booking!
      if args[:issue].nil?
        # create a virtual booking
        proj = Project.where(:id => args[:project_id]).first
        if User.current.allowed_to?(:log_time, proj)
          self.project = proj
          write_attribute(:project_id, proj.id)
        end
        self.update_attributes({:virtual => true, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at]})
        self.comments = args[:comments]
      else
        # create a normal booking
        # to enforce a user to "log time" the admin has to set the redmine permissions
        # current user could be the user himself or the admin. whoever it is, the peron needs the permission to do that
        # but in any way, the user_id which will be stored, is the user_id from the timeLog. this way the admin can book
        # times for any of his users..
        if User.current.allowed_to?(:log_time, args[:issue].project)
          # TODO check for user-specific setup (limitations for bookable times etc)
          time_entry = create_time_entry({:issue => args[:issue], :user_id => args[:user_id], :comments => args[:comments], :started_on => args[:started_on], :activity_id => args[:activity_id], :hours => args[:hours]})
          super({:time_entry_id => time_entry.id, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at], :project_id => args[:issue].project.id})
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
    return unless self.user.id == User.current.id || User.current.admin? # users should only change their own entries or be admin
    user = self.user # use the user-info from the TimeLog, so the admin can change normal users entries too...
    comments = self.comments # store comments temporarily to swap them to the new place

    # we only have to do something if the issue really changes
    if issue.nil? && self.issue != l(:time_tracker_label_none) # self not virtual but new issue is nil => self became virtual
      self.time_entry.destroy

      write_attribute(:virtual, true)
      write_attribute(:comments, comments) # should create a virtual comment
    elsif !issue.nil? && issue.id != self.issue_id && user.allowed_to?(:log_time, issue.project) # issue changes
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
    # only virtual bookings can choose projects. otherwise, the project will be set through the issue
    write_attribute(:project_id, nil) if self.virtual? && project.nil?
    write_attribute(:project_id, project.id) if self.virtual? && self.user.allowed_to?(:log_time, project)
  end

  # this method is necessary to change start and stop at the same time without leaving boundaries
  def update_time(start, stop)
    return if start < self.time_log.started_on || start >= self.time_log.stopped_at || stop <= self.time_log.started_on || stop > self.time_log.stopped_at || start == stop

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
    self.time_log.user
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
