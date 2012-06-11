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
    default_args = {:started_on => self.started_on, :stopped_at => self.stopped_at, :comments => self.comments, :activity_id => 1, :issue_id => nil}
    args = default_args.merge(args)
    # without an issue it's not possible to add a booking'
    unless args[:issue_id].nil?
      issue = issue_from_id(args[:issue_id])
      hours = hours_spent(args[:started_on], args[:stopped_at])
      # limit the booking to maximum bookable time
      if hours > bookable_hours
        args[:stopped_at] = args[:started_on] + bookable_hours
      end
      # TODO check for user-specific setup (limitations for bookable times etc)
      # create a timeBooking to combine a timeLog-entry and a timeEntry
      ActiveRecord::Base.transaction do
        time_entry = issue.time_entries.create(:comments => args[:comments], :spent_on => args[:started_on], :hours => hours, :activity_id => args[:activity_id])
        # due to the mass-assignment security, we have to set the user_id extra
        time_entry.user_id = user_id
        time_entry.save
        TimeBooking.create(:time_entry_id => time_entry.id, :time_log_id => id, :started_on => args[:started_on], :stopped_at => args[:stopped_at])
      end
    end
  end

  # TODO move this function into a helper due to DRY
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  # returns the hours between two timestamps
  def hours_spent(time1 = started_on, time2 = stopped_at)
    ((time2.to_i - time1.to_i) / 3600.0).to_f
  end

  # returns the sum of bookable time of an time entry
  def bookable_hours
    if time_bookings.empty?
      # log was not booked at all, so the whole time is bookable
      hours_spent
    else
      # every gap between the bookings represents bookable time so we sum up the time to show it as bookable time
      time_booked = 0
      time_bookings.each do |tb|
        time_booked += tb.hours_spent
      end
      hours_spent - time_booked
    end
  end
end
