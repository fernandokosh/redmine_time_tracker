class TimeBookingsController < ApplicationController
  unloadable

  before_filter :authorize_global

  def index
  end

  def delete
    time_booking = TimeBooking.where(:id => params[:id]).first
    if time_booking.nil?
      flash[:error] = l(:time_tracker_delete_booking_fail)
      redirect_to :back
    else
      tl = TimeLog.where(:id => time_booking.time_log_id, :user_id => User.current.id).first
      time_booking.destroy
      tl.check_bookable # we should set the bookable_flag after deleting bookings
      flash[:success] = l(:time_tracker_delete_booking_success)
      redirect_to :back
    end
  end
end