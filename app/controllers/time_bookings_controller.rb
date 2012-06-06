class TimeBookingsController < ApplicationController
  unloadable

  def index
  end

  def delete
    time_booking = TimeBooking.where(:id => params[:id]).first
    if time_booking.nil?
      render :text => l(:time_tracker_delete_booking_fail)
    else
      time_booking.destroy
      render :text => l(:time_tracker_delete_booking_success)
    end
  end
end