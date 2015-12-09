class TtReportingController < ApplicationController

  menu_item :time_tracker_menu_tab_reporting
  before_filter :authorize_global, :check_settings_for_ajax

  helper :issues
  include IssuesHelper
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include TtSortHelper
  helper :time_trackers
  include TimeTrackersHelper
  helper :report_sidebar

  def index
    fetch_query

    if @query_reports.valid?
      @limit = per_page_option

      @booking_count = @query_reports.bookings.count
      @booking_pages = Paginator.new @booking_count, @limit, params['page_bookings']
      @offset ||= @booking_pages.offset
      @bookings = @query_reports.bookings(:order => sort_bookings_clause,
                                           :offset => @offset,
                                           :limit => @limit)
      @booking_count_by_group = @query_reports.booking_count_by_group
      @total_booked_time = help.time_dist2string((total_booked*60).to_i)
    end

    fetch_chart_data

    render :template => 'tt_reporting/index', :locals => {:query => @query_reports}
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  WWW_START_REGEXP = /^www/
  HTTP_START_REGEXP = /^http[s]?:\/\//

  def print_report
    fetch_query

    if @query_reports.valid?
      @booking_count = @query_reports.booking_count
      @bookings = @query_reports.bookings(:order => sort_bookings_clause)
      @booking_count_by_group = @query_reports.booking_count_by_group
    end

    @total_booked_time = help.time_dist2string((total_booked*60).to_i)
    fetch_chart_data

    # prepare logo settings
    @logo_url = Setting.plugin_redmine_time_tracker[:report_logo_url]
    @logo_url = "http://#{@logo_url}" if @logo_url =~ WWW_START_REGEXP
    @logo_external = @logo_url =~ HTTP_START_REGEXP ? true : false
    @logo_width = Setting.plugin_redmine_time_tracker[:report_logo_width]
    @logo_width = "150" if @logo_width.blank?

    render "print_report", :layout => false, :locals => {:query => @query_reports}
  end

  private

  def total_booked
    hours = 0
    @query_reports.bookings.each do |tb|
      hours += tb.hours_spent
    end
    hours
  end

  def fetch_query
    query_from_id
    reports_query

    unless help.permission_checker([:tt_view_bookings, :tt_edit_bookings], {}, true)
      @query_reports.filters[:tt_user] = {:operator => "=", :values => [User.current.id.to_s]}
    end

    sort_init(@query_reports.sort_criteria.empty? ? [['tt_booking_date', 'desc']] : @query_reports.sort_criteria)
    tt_sort_update(:sort_bookings, @query_reports.sortable_columns, "tt_booking_sort")
  end

  def fetch_chart_data
    @chart_data = Array.new
    @chart_ticks = Array.new
    @highlighter_data = Array.new

    if @query_reports.valid? && !(@bookings.empty? || @bookings.nil?)
      # if the user changes the date-order for the table values, we have to reorder it for the chart
      start_date = [@bookings.last.started_on.to_date, @bookings.first.started_on.to_date].min
      stop_date = [@bookings.last.started_on.to_date, @bookings.first.started_on.to_date].max

      (start_date..stop_date).map do |date|
        hours = 0
        @bookings.each do |tb|
          hours += tb.hours_spent if tb.started_on.to_date == date
        end
        @chart_data.push(hours)
        @highlighter_data.push([date, hours])

        # to get readable labels, we have to blank out some of them if there are to many
        # only set 8 labels and set the other blank
        gap = ((stop_date - start_date)/8).ceil
        if gap == 0 || (date - start_date) % gap == 0
          @chart_ticks.push(date)
        else
          @chart_ticks.push("")
        end
      end
    end
  end

  def check_settings_for_ajax
    flash[:error] = l(:force_auth_requires_rest_api) if Setting.login_required? && !Setting.rest_api_enabled?
  end
end
