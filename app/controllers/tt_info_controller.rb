class TtInfoController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_active_trackers
  before_filter :authorize_global

  def index
    if User.current.allowed_to?(:view_others_time_trackers, nil, :global => true) || User.current.admin?
      @time_trackers = TimeTracker.all
    else
      @time_trackers = TimeTracker.where(:user_id => User.current.id).all
    end
  end
end