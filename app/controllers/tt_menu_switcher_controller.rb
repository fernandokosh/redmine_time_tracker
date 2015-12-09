class TtMenuSwitcherController < ApplicationController

  # this controller should dynamically redirect the user to an TimeTracker-page is is allowed to see,
  # if he clicks on the TimeTracker-Menu at the Top-Menu from redmine
  def index
    if User.current.allowed_to_globally?({:controller => 'tt_overview', :action => 'index'}, {})
      redirect_to :controller => 'tt_overview', :action => 'index'
    elsif User.current.allowed_to_globally?({:controller => 'tt_bookings_list', :action => 'index'}, {})
      redirect_to :controller => 'tt_bookings_list', :action => 'index'
    elsif User.current.allowed_to_globally?({:controller => 'tt_logs_list', :action => 'index'}, {})
      redirect_to :controller => 'tt_logs_list', :action => 'index'
    elsif User.current.allowed_to_globally?({:controller => 'tt_info', :action => 'index'}, {})
      redirect_to :controller => 'tt_info', :action => 'index'
    elsif User.current.allowed_to_globally?({:controller => 'tt_reporting', :action => 'index'}, {})
      redirect_to :controller => 'tt_reporting', :action => 'index'
    else
      render_403
    end
  end
end