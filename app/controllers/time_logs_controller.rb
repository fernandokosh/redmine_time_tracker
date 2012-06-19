class TimeLogsController < ApplicationController
  unloadable

  before_filter :authorize_global

  def index

  end

  def add_booking
    issue = issue_from_id(params[:issue_id])
    if User.current.allowed_to?(:log_time, issue.project)
      time_log = TimeLog.where(:id => params[:time_log_id]).first
      time_log.add_booking(:hours => params[:hours], :comments => params[:comments], :issue => issue)
      redirect_to '/time_trackers'
    else
      flash[:error] = "not allowed to do that.. :)"
      redirect_to '/time_trackers'
    end
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