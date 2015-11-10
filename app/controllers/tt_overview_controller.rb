class TtOverviewController < ApplicationController

  menu_item :time_tracker_menu_tab_overview
  before_filter :authorize_global, :check_settings_for_ajax

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :tt_sort
  include TtSortHelper
  helper :time_trackers
  include TimeTrackersHelper

  def index
    @time_tracker = get_current_time_tracker

    @limit = 15 # limit for both lists

    # time_log list  =======================

    query_from_id
    # prepare query for time_logs
    time_logs_query
    # group list by date per default // TODO replace this with some kind of user-settings later!
    @query_logs.group_by ||= "tt_log_date"
    @query_logs.filters = {:tt_user => {:operator => "=", :values => [User.current.id.to_s]}, :tt_log_bookable => {:operator => "=", :values => ["1"]}, :tt_start_date => {:operator => ">=", :values => [(Time.now.localtime-2.weeks).beginning_of_day.to_s]}}
    sort_init(@query_logs.sort_criteria.empty? ? [['tt_log_date', 'desc']] : @query_logs.sort_criteria)
    tt_sort_update(:sort_logs, @query_logs.sortable_columns, "tt_log_sort")

    if @query_logs.valid?
      @log_count = @query_logs.log_count
      @log_pages = Paginator.new @log_count, @limit, params['page_logs'], 'page_logs'
      @log_offset ||= @log_pages.offset
      @logs = @query_logs.logs(:order => sort_logs_clause,
                               :offset => @log_offset,
                               :limit => @limit)
      @log_count_by_group = @query_logs.log_count_by_group
    end

    # time_bookings list  =======================

    time_bookings_query

    # group list by date per default // TODO replace this with some kind of user-settings later!
    @query_bookings.group_by ||= "tt_booking_date"

    #show only the actual users entries from the last 2 weeks
    @query_bookings.filters = {:tt_user => {:operator => "=", :values => [User.current.id.to_s]}, :tt_start_date => {:operator => ">=", :values => [(Time.now.localtime-2.weeks).beginning_of_day.to_s]}}

    sort_init(@query_bookings.sort_criteria.empty? ? [['tt_booking_date', 'desc']] : @query_bookings.sort_criteria)
    tt_sort_update(:sort_bookings, @query_bookings.sortable_columns, "tt_booking_sort")

    if @query_bookings.valid?
      @booking_count = @query_bookings.bookings.count
      @booking_pages = Paginator.new @booking_count, @limit, params['page_bookings'], 'page_bookings'
      @booking_offset ||= @booking_pages.offset
      @bookings = @query_bookings.bookings(:order => sort_bookings_clause,
                                           :offset => @booking_offset,
                                           :limit => @limit)
      @booking_count_by_group = @query_bookings.booking_count_by_group
    end
  end

  private

  def check_settings_for_ajax
    flash[:error] = l(:force_auth_requires_rest_api) if Setting.login_required? && !Setting.rest_api_enabled?
  end
end
