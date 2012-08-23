class TimeLogsController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs
  before_filter :authorize_global

  include TimeTrackersHelper

  def index
  end

  # TODO localize messages
  def add_booking
    tl = params[:time_log]
    time_log = TimeLog.where(:id => tl[:id]).first
    issue = issue_from_id(tl[:issue_id])
    time_log.add_booking(:start_time => tl[:start_time], :stop_time => tl[:stop_time], :spent_time => tl[:spent_time],
                         :comments => tl[:comments], :issue => issue, :project_id => params[:project_id_select])
    flash[:notice] = l(:success_add_booking)
  rescue BookingError => e
    flash[:error] = e.message
  ensure
    redirect_to '/tt_overview'
  end

  def update
    tl = params[:time_log]
    time_log = TimeLog.where(:id => tl[:id]).first
    if time_log.user_id == User.current.id || User.current.admin?
      start = Time.parse(tl[:tt_log_date] + " " + tl[:start_time])
      hours = time_string2hour(tl[:spent_time])
      stop = start + hours.hours

      time_log.update_attributes!(:started_on => start, :stopped_at => stop, :comments => tl[:comments])
    end
    redirect_to '/tt_overview'
  end

  def delete
    if User.current.admin?
      time_log = TimeLog.where(:id => params[:time_log_id]).first
      unless time_log.nil?
        if time_log.time_bookings.count == 0
          time_log.destroy
        else
          booked_time = time_log.hours_spent - time_log.bookable_hours
          time_log.stopped_at = time_log.started_on + booked_time.hours
          time_log.bookable = false
          time_log.save!
        end
      end
    end
    redirect_to '/tt_overview'
  end

  def show_booking
    @time_log = TimeLog.where(:id => params[:time_log_id]).first
    render(:update) { |page| page.replace_html 'entry-'+params[:time_log_id], :partial => 'time_logs/booking_form' }
  end

  def show_edit
    @time_log = TimeLog.where(:id => params[:time_log_id]).first
    render(:update) { |page| page.replace_html 'entry-'+params[:time_log_id], :partial => 'time_logs/edit_form' }
  end

  def get_list_entry
    # prepare query for time_logs
    time_logs_query

    entry = TimeLog.where(:id => params[:time_log_id]).first
    render :update do |page|
      page.replace_html 'entry-'+params[:time_log_id], :partial => 'time_logs/list_entry', :locals => {:entry => entry, :query => @query_logs}
      page << "new ContextMenu('#{ url_for(tt_overview_context_menu_path) }')" # workaround for strange contextMenu-problem
    end
  end

end