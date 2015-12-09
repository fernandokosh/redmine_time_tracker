class TimeBookingsController < ApplicationController

  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper_method :get_activities
  include TimeTrackersHelper

  def actions
    unless params[:time_booking_edit].nil?
      tb_e = params[:time_booking_edit]
      tb_e.keys.each do |tb_key|
        update tb_e[tb_key]
      end
    end

    redirect_to :back
  end

  def show_edit
    @time_bookings = TimeBooking.where(:id => params[:time_booking_ids]).all
    respond_to do |format|
      format.js
    end
  end

  def delete
    if help.permission_checker([:tt_edit_own_bookings, :tt_edit_bookings], {}, true)
      time_bookings = TimeBooking.where(:id => params[:time_booking_ids]).all
      time_bookings.each do |item|
        if item.user == User.current && User.current.allowed_to?(:tt_edit_own_bookings, item.project) || User.current.allowed_to?(:tt_edit_bookings, item.project)
          tl = TimeLog.where(:id => item.time_log_id, :user_id => item.user.id).first
          item.destroy
          tl.check_bookable # we should set the bookable_flag after deleting bookings
        else
          raise StandardError, l(:tt_error_not_allowed_to_delete_bookings)
        end
      end
      flash[:notice] = l(:time_tracker_delete_booking_success)
    else
      raise StandardError, l(:tt_error_not_allowed_to_delete_bookings)
    end
    redirect_to :back
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to :back
  end

# TODO check if there should be done TimeBooking.visible.where....
  def get_list_entry
    # prepare query for time_bookings
    time_bookings_query

    @entry = TimeBooking.where(:id => params[:time_booking_id]).first
    respond_to do |format|
      format.js
    end
  end

  private

  def update(tb)
    time_booking = TimeBooking.find(tb[:id])
    tl = time_booking.time_log
    issue = Issue.where(id: tb[:issue_id]).first
    project = issue.nil? ? Project.find(tb[:project_id]) : issue.project

    start = build_timeobj_from_strings parse_localised_date_string(tb[:tt_booking_date]), parse_localised_time_string(tb[:start_time])
    hours = time_string2hour(tb[:spent_time])
    stop = start + hours.hours
    time_booking.update_time(start, stop)

    # only set project separately if no issue is set, otherwise the project from the issue is taken
    time_booking.update_attributes!(:project => project) if issue.nil?
    # have to set issue separately due to mass-assignment-rules
    # TODO check if there is a security problem due to mass-assignment here!)
    time_booking.update_attributes!({:comments => tb[:comments], :issue => issue, :activity_id => tb[:activity_id]})

    tl.check_bookable
    flash[:notice] = l(:tt_update_booking_success)
  rescue StandardError => e
    flash[:error] = e.message
  end
end
