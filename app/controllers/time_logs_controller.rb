class TimeLogsController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs
  before_filter :authorize_global

  def index
  end

  # TODO localize messages
  def add_booking
    tl = params[:time_log]
    time_log = TimeLog.where(:id => tl[:id]).first
    issue = issue_from_id(tl[:issue_id])
    if time_log.add_booking(:start_time => tl[:start_time], :stop_time => tl[:stop_time], :spent_time => tl[:spent_time],
                            :comments => tl[:comments], :issue => issue, :project_id => params[:project_id_select])
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