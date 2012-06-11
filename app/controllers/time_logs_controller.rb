class TimeLogsController < ApplicationController
  unloadable

  def index
    user = User.current
    #@user_time_logs = TimeLog.get_partial_booked_logs
    @bookable_logs = []
    user.time_logs.each do |tl|
      @bookable_logs.push(tl) if tl.bookable_hours > 0
    end
    @user_bookings = TimeBooking.get_bookings
  end

  def add_booking
    time_log = TimeLog.where(:id => params[:time_log_id]).first
    #time_log.add_booking(params)
    time_log.add_booking(:hours => params[:hours], :comments => params[:comments], :issue_id => params[:issue_id])
    render :controller => "time_logs", :action => "index"
  end

  def show_booking
    @time_log = TimeLog.where(:id => params[:time_log_id]).first
    render :partial => 'booking_form'
  end
end