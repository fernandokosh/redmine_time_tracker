module TimeTrackersHelper
    def issue_from_id(issue_id)
        Issue.find(:first, :conditions => { :id => issue_id })
    end

    def user_from_id(user_id)
        User.find(:first, :conditions => { :id => user_id })
    end
end
