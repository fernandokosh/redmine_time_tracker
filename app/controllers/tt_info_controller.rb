class TtInfoController < ApplicationController

  menu_item :time_tracker_menu_tab_active_trackers
  before_filter :authorize_global, :check_settings_for_ajax

  def index
    if User.current.allowed_to?(:view_others_time_trackers, nil, :global => true) || User.current.admin?
      @time_trackers = TimeTracker.all
    else
      @time_trackers = TimeTracker.where(:user_id => User.current.id).all
    end
  end

  private

  def check_settings_for_ajax
    flash[:error] = l(:force_auth_requires_rest_api) if Setting.login_required? && !Setting.rest_api_enabled?
  end
end