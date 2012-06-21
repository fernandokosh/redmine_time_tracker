class TimeLogsController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs
  before_filter :authorize_global

  def index
  end

  # TODO localize messages
  def add_booking
    time_log = TimeLog.where(:id => params[:time_log_id]).first
    issue = issue_from_id(params[:issue_id])
    if time_log.add_booking(:hours => params[:hours], :comments => params[:comments], :issue => issue, :virtual => params[:virtual])
      flash[:notice] = "success :D"
    else
      flash[:error] = "not allowed to do that.. :)"
    end
    redirect_to '/time_trackers'
  end

  def show_booking
    @time_log = TimeLog.where(:id => params[:time_log_id]).first
    render :partial => 'booking_form'
  end

  private

  # TODO move this function into a helper due to DRY
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end
end