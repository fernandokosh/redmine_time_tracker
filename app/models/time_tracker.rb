# Helper access from the model
def help
    Helper.instance
end

class Helper
    include Singleton
    include TimeTrackersHelper
end

class TimeTracker < ActiveRecord::Base
    belongs_to :user
    has_one :issue

    validates_presence_of :issue_id

    def initialize(arguments = nil)
        super(arguments)
        self.user_id = User.current.id
        self.started_on = Time.now
        self.time_spent = 0.0
        self.paused = false
    end
   
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

        issue = help.issue_from_id(self.issue_id)
        if issue.nil? or !user.allowed_to?(:log_time, issue.project)
            return true
        end

        return false
    end

    protected

    def running_time
        if paused
            return 0
        else
            return ((Time.now.to_i - started_on.to_i) / 3600.0).to_f
        end
    end
end
