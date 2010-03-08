module ApplicationHelper
    def time_tracker_for(user)
        TimeTracker.find(:first, :conditions => { :user_id => user.id })
    end
end

