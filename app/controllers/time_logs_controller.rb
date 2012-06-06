class TimeLogsController < ApplicationController
  unloadable

  def index
    user = User.current
    #@user_time_logs = TimeLog.get_unbooked_logs
    @user_time_logs = TimeLog.get_partial_booked_logs
    @user_bookings = TimeBooking.get_bookings
  end

  def book

  end
end