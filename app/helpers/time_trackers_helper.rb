module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.first(:conditions => {:id => issue_id})
  end

  def user_from_id(user_id)
    User.first(:conditions => {:id => user_id})
  end
end
