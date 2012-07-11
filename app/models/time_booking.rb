class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id, :virtual, :project
  belongs_to :project
  belongs_to :time_log
  belongs_to :time_entry, :dependent => :delete
  has_one :virtual_comment, :dependent => :delete

  validates_presence_of :time_log_id
  validates :time_entry_id, :presence => true, :unless => Proc.new { |tb| tb.virtual }
  validates_associated :virtual_comment, :if => Proc.new { |tb| tb.virtual }

  def initialize(args = {}, options = {})
    ActiveRecord::Base.transaction do
      super(nil)
      # without issue_id, create an virtual booking!
      if args[:issue].nil?
        # create a virtual booking
        super({:virtual => true, :time_log_id => args[:time_log_id], :project_id => args[:project_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at]})
        self.save
        # this part looks not very Rails like yet... should refactor it if any time to
        vcomment = VirtualComment.where(:time_booking_id => self.id).first_or_create
        vcomment.update_attributes(:comments => args[:comments])
      else
        # create a normal booking
        # to enforce a user to "log time" the admin has to set the redmine permissions
        # current user could be the user himself or the admin. whoever it is, the peron needs the permission to do that
        # but in any way, the user_id which will be stored, is the user_id from the timeLog. this way the admin can book
        # times for any of his users..
        if User.current.allowed_to?(:log_time, args[:issue].project)
          # TODO check for user-specific setup (limitations for bookable times etc)
          # create a timeBooking to combine a timeLog-entry and a timeEntry
          time_entry = args[:issue].time_entries.create({:comments => args[:comments], :spent_on => args[:started_on], :activity_id => args[:activity_id]})
          time_entry.hours = args[:hours]
          # due to the mass-assignment security, we have to set the user_id extra
          time_entry.user_id = args[:user_id]
          time_entry.save
          super({:time_entry_id => time_entry.id, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at, :project => args[:issue].project]})
        end
      end
    end
  end

  def hours_spent
    ((stopped_at.to_i - started_on.to_i) / 3600.0).to_f
  end

  def get_formatted_time(time1 = started_on, time2 = stopped_at)
    time_dist2string(time2.to_i - time1.to_i)
  end

  # TODO this method should be a helper hence it was used in TimeLog and TimeBooking the same way!
  def time_dist2string(dist)
    h = dist / 3600
    m = (dist - h*3600) / 60
    s = dist - (h*3600 + m*60)
    h<10 ? h="0#{h}" : h = h.to_s
    m<10 ? m="0#{m}" : m = m.to_s
    s<10 ? s="0#{s}" : s = s.to_s
    h + ":" + m + ":" + s
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

  #def project
  #  if self.virtual
  #    pid = self.time_log.project_id
  #    Project.find(pid) unless pid.nil?
  #    #self.time_log.project
  #  else
  #    self.time_entry.project
  #  end
  #end

  def user
    self.time_log.user
  end

end
