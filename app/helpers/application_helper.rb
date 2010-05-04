module ApplicationHelper
    def time_tracker_for(user)
        TimeTracker.find(:first, :conditions => { :user_id => user.id })
    end

    def global_allowed_to?(user, action)
        return false if user.nil?

        projects = Project.find(:all)
        for p in projects
            if user.allowed_to?(action, p)
                return true
            end
        end

        return false
    end
end

