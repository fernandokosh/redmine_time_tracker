module TimeTrackersHelper
  def user_from_id(user_id)
    User.where(:id => user_id).first
  end
end
