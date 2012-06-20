class TimeLog < ActiveRecord::Base
  unloadable

  attr_accessible :user_id, :started_on, :stopped_at, :project_id, :comments
  # using the virtual-flag for objects that should never been saved to the database
  attr_accessor :virtual
  belongs_to :user
  has_many :time_bookings
  has_many :time_entries, :through => :time_bookings

  def initialize(arguments = nil, *args)
    super(arguments)
  end

  # if issue is the only parameter we get, we will book the whole time to one issue
  def add_booking(args = {})
    # TODO not set activity_id default value to 1 / only for testing because redmine requires activity_id
    default_args = {:started_on => self.started_on, :stopped_at => self.stopped_at, :comments => self.comments, :activity_id => 1, :issue => nil, :hours => nil}
    args = default_args.merge(args)
    # without an issue it's not possible to add a booking'
    unless args[:issue].nil?
      # to enforce a user to "log time" the admin has to set the redmine permissions
      if User.current.allowed_to?(:log_time, args[:issue].project)
        args[:hours].nil? ? hours = hours_spent(args[:started_on], args[:stopped_at]) : hours = args[:hours].to_f
        # limit the booking to maximum bookable time
        if hours > bookable_hours
          hours = bookable_hours
        end
        args[:stopped_at] = Time.at(args[:started_on].to_i + (hours * 3600).to_i).getutc

        # TODO check for user-specific setup (limitations for bookable times etc)
        # create a timeBooking to combine a timeLog-entry and a timeEntry
        ActiveRecord::Base.transaction do
          time_entry = args[:issue].time_entries.create(:comments => args[:comments], :spent_on => args[:started_on], :hours => hours, :activity_id => args[:activity_id])
          # due to the mass-assignment security, we have to set the user_id extra
          time_entry.user_id = user_id
          time_entry.save
          TimeBooking.create(:time_entry_id => time_entry.id, :time_log_id => id, :started_on => args[:started_on], :stopped_at => args[:stopped_at])
        end
      end
    end
  end

  # returns the hours between two timestamps
  def hours_spent(time1 = started_on, time2 = stopped_at)
    ((time2.to_i - time1.to_i) / 3600.0).to_f
  end

  # returns the sum of bookable time of an time entry
  # if log was not booked at all, so the whole time is bookable
  def bookable_hours
    # every gap between the bookings represents bookable time so we sum up the time to show it as bookable time
    time_booked = 0
    time_bookings.each do |tb|
      time_booked += tb.hours_spent
    end
    hours_spent - time_booked
  end
end
