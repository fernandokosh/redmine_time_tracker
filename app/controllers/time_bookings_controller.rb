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
      time_booking.destroy
      flash[:success] = l(:time_tracker_delete_booking_success)
      redirect_to :back
    end
  end
end