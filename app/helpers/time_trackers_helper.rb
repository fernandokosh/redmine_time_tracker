module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  def user_from_id(user_id)
    User.where(:id => user_id).first
  end
end
