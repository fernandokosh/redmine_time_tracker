class TimeBookingsController < ApplicationController
  unloadable

  before_filter :authorize_global

  include TimeTrackersHelper

  def actions
    unless params[:time_booking_edit].nil?
      tb_e = params[:time_booking_edit]
      tb_e.keys.each do |tb_key|
        update tb_e[tb_key]
      end
    end

    redirect_to '/tt_overview'
  end

  def show_edit
    @time_booking = TimeBooking.where(:id => params[:time_booking_id]).first
    render(:update) { |page| page.replace_html 'booking-entry-'+params[:time_booking_id], :partial => 'time_bookings/edit_form' }
  end

  def update(tb)
    time_booking = TimeBooking.where(:id => tb[:id]).first
    tl = time_booking.time_log
    issue = Issue.where(:id => tb[:issue_id]).first
    issue.nil? ? project = Project.where(:id => tb[:project_id]).first : project = issue.project

    if time_booking.user.id == User.current.id || User.current.admin?
      start = Time.parse(tb[:tt_booking_date] + " " + tb[:start_time])
      hours = time_string2hour(tb[:spent_time])
      stop = start + hours.hours

      time_booking.update_time(start, stop)

      time_booking.issue = issue
      time_booking.project = project if issue.nil?
      time_booking.comments = tb[:comments]

      time_booking.save!
      tl.check_bookable
    end
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

  def get_list_entry
    # prepare query for time_bookings
    time_bookings_query

    entry = TimeBooking.where(:id => params[:time_booking_id]).first
    render :update do |page|
      page.replace_html 'booking-entry-'+params[:time_booking_id], :partial => 'time_bookings/list_entry', :locals => {:entry => entry, :query => @query_bookings, :button => :book}
      page << "new ContextMenu('#{ url_for(tt_overview_context_menu_path) }')" # workaround for strange contextMenu-problem
    end
  end
end