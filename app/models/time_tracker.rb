class TimeTracker < ActiveRecord::Base
    belongs_to :user
    has_one :issue

    validates_presence_of :issue_id

    def initialize(arguments = nil)
        super(arguments)
        self.user_id = User.current.id
        self.started_on = Time.now
    end

    def hours_spent
        ((Time.now.to_i - started_on.to_i) / 3600.0).to_f
    end

    def time_spent_to_s
        hours, minutes = Date.day_fraction_to_time(DateTime.now - started_on.to_datetime)
        hours.to_s + l(:time_tracker_hour_sym) + minutes.to_s.rjust(2, '0')
    end
end

