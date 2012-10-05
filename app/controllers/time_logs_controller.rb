class TimeLogsController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs
  before_filter :authorize_global

  include TimeTrackersHelper

  def actions
    unless params[:time_log_add_booking].nil?
      tl_add_booking = params[:time_log_add_booking]
      tl_add_booking.keys.each do |tl_key|
        add_booking tl_add_booking[tl_key]
      end
    end

    unless params[:time_log_edit].nil?
      tl_eb = params[:time_log_edit]
      tl_eb.keys.each do |tl_key|
        update tl_eb[tl_key]
      end
    end

    redirect_to :controller => 'tt_overview'
  end

  def add_booking(tl)
    time_log = TimeLog.where(:id => tl[:id]).first
    issue = issue_from_id(tl[:issue_id])
    time_log.add_booking(:start_time => tl[:start_time], :stop_time => tl[:stop_time], :spent_time => tl[:spent_time],
                         :comments => tl[:comments], :issue => issue, :project_id => tl[:project_id])
    flash[:notice] = l(:success_add_booking)
  rescue BookingError => e
    flash[:error] = e.message
  end

  def update(tl)
    time_log = TimeLog.where(:id => tl[:id]).first
    if time_log.user_id == User.current.id || User.current.admin?
      start = Time.parse(tl[:tt_log_date] + " " + tl[:start_time])
      hours = time_string2hour(tl[:spent_time])
      stop = start + hours.hours

      time_log.update_attributes!(:started_on => start, :stopped_at => stop, :comments => tl[:comments])
    end
  end

  def delete
    if User.current.admin?
      time_logs = TimeLog.where(:id => params[:time_log_ids]).all
      time_logs.each do |item|
        if item.time_bookings.count == 0
          item.destroy
        else
          booked_time = item.hours_spent - item.bookable_hours
          item.stopped_at = item.started_on + booked_time.hours
          item.bookable = false
          item.save!
        end
      end
    end
    redirect_to :controller => 'tt_overview'
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

end