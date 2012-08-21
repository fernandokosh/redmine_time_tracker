class TtInfoController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_active_trackers
  before_filter :authorize_global

  def index
    #if User.current.allowed_to?(:view_others_time_trackers, nil, :global => true)
    @time_trackers = TimeTracker.all
  end
end