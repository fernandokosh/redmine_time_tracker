class TimeBooking < ActiveRecord::Base
  unloadable

  attr_accessible :started_on, :stopped_at, :time_entry_id, :time_log_id, :virtual
  belongs_to :time_log
  belongs_to :time_entry, :dependent => :delete
  has_one :virtual_comment, :dependent => :delete

  validates_presence_of :time_log_id
  validates :time_entry_id, :presence => true, :unless => Proc.new { |tb| tb.virtual }
  validates_associated :virtual_comment, :if => Proc.new { |tb| tb.virtual }

  def initialize(args = {}, options = {})
    ActiveRecord::Base.transaction do
      super(nil)
      if args[:issue].nil? && args[:virtual].nil?
        false
      elsif args[:virtual]
        # create a virtual booking
        super({:virtual => true, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at]})
        self.save
        # this part looks not very Rails like yet... should refactor it if any time to
        vcomment = VirtualComment.where(:time_booking_id => self.id).first_or_create
        vcomment.update_attributes(:comments => args[:comments])
      elsif !args[:issue].nil?
        # create a normal booking
        # to enforce a user to "log time" the admin has to set the redmine permissions
        # current user could be the user himself or the admin. whoever it is, the peron needs the permission to do that
        # but in any way, the user_id which will be stored, is the user_id from the timeLog. this way the admin can book
        # times for any of his users..
        if User.current.allowed_to?(:log_time, args[:issue].project)
          # TODO check for user-specific setup (limitations for bookable times etc)
          # create a timeBooking to combine a timeLog-entry and a timeEntry
          time_entry = args[:issue].time_entries.create(:comments => args[:comments], :spent_on => args[:started_on], :hours => args[:hours], :activity_id => args[:activity_id])
          # due to the mass-assignment security, we have to set the user_id extra
          time_entry.user_id = args[:user_id]
          time_entry.save
          super({:time_entry_id => time_entry.id, :time_log_id => args[:time_log_id], :started_on => args[:started_on], :stopped_at => args[:stopped_at]})
        end
      end
    end
  end

  def hours_spent
    ((stopped_at.to_i - started_on.to_i) / 3600.0).to_f
  end
end
