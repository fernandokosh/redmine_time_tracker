class TimeLogsController < ApplicationController

  menu_item :time_tracker_menu_tab_logs
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper_method :get_activities
  include TimeTrackersHelper

  def actions
    last_added_booking_ids = Array.new

    unless params[:time_log_add_booking].nil?
      tl_add_booking = params[:time_log_add_booking]
      tl_add_booking.keys.each do |tl_key|
        last_added_booking_id = add_booking tl_add_booking[tl_key]
        last_added_booking_ids.push last_added_booking_id if last_added_booking_id.present?
      end
    end

    unless params[:time_log_edit].nil?
      tl_eb = params[:time_log_edit]
      tl_eb.keys.each do |tl_key|
        update tl_eb[tl_key]
      end
    end

    # send information which id's are touched to implement highlighting
    redirect_to :controller => URI(request.referer).path.split('/').last, :tl_labids => last_added_booking_ids
  end

  def delete
    if help.permission_checker([:tt_edit_own_time_logs, :tt_edit_time_logs], {}, true)
      time_logs = TimeLog.where(:id => params[:time_log_ids]).all
      time_logs.each do |item|
        if item.user == User.current && User.current.allowed_to_globally?(:tt_edit_own_time_logs, {}) || User.current.allowed_to_globally?(:tt_edit_time_logs, {})
          if item.time_bookings.count == 0
            item.destroy
          else
            raise StandardError, l(:tt_error_not_possible_to_delete_logs)
          end
        else
          flash[:error] = l(:tt_error_not_allowed_to_delete_logs)
        end
      end
      flash[:notice] = l(:tt_success_delete_time_logs)
    else
      flash[:error] = l(:tt_error_not_allowed_to_delete_logs)
    end
    redirect_to :back
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to :back
  end

  def trim
    if item.time_bookings.count == 1
      booked_time = item.hours_spent - item.bookable_hours
      item.stopped_at = item.started_on + booked_time.hours
      item.bookable = false
      item.save!
    end
  end

  def show_booking
    @time_logs = TimeLog.where(:id => params[:time_log_ids]).all
    respond_to do |format|
      format.js
    end
  end

  def show_edit
    @time_logs = TimeLog.where(:id => params[:time_log_ids]).all
    respond_to do |format|
      format.js
    end
  end

  def get_list_entry
    # prepare query for time_logs
    time_logs_query

    @entry = TimeLog.where(:id => params[:time_log_id]).first
    respond_to do |format|
      format.js
    end
  end

  private

  def add_booking(tl)
    time_log = TimeLog.where(:id => tl[:id]).first
    issue = issue_from_id(tl[:issue_id])
    last_added_booking_id = time_log.add_booking(:start_time => tl[:start_time], :stop_time => tl[:stop_time], :spent_time => tl[:spent_time],
                                                 :comments => tl[:comments], :issue => issue, :project_id => tl[:project_id], :activity_id => tl[:activity_id])
    flash[:notice] = l(:success_add_booking)
    last_added_booking_id
  rescue StandardError => e
    flash[:error] = e.message
    nil
  end

  def update(tl)
    time_log = TimeLog.where(:id => tl[:id]).first
    start = build_timeobj_from_strings parse_localised_date_string(tl[:tt_log_date]), parse_localised_time_string(tl[:start_time])
    hours = time_string2hour(tl[:spent_time])
    stop = start + hours.hours

    time_log.update_attributes!(:started_on => start, :stopped_at => stop, :comments => tl[:comments])
    flash[:notice] = l(:tt_update_log_success)
  rescue StandardError => e
    flash[:error] = e.message
  end
end