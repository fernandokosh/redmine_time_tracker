class TtOverviewController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_overview
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :time_trackers
  include TimeTrackersHelper

  def index
    @time_tracker = get_current_time_tracker

    @limit = 15 # limit for both lists

    # time_log list  =======================

    # prepare query for time_logs
    time_logs_query
    # group list by date per default // TODO replace this with some kind of user-settings later!
    @query_logs.group_by ||= "tt_log_date"

    sort_init(@query_logs.sort_criteria.empty? ? [['tt_log_id', 'desc']] : @query_logs.sort_criteria)
    tt_sort_update(:sort_logs, @query_logs.sortable_columns, "tt_log_sort")

    if @query_logs.valid?
      #@limit = per_page_option
      @log_count = @query_logs.log_count
      @log_pages = Paginator.new self, @log_count, @limit, params['page_logs']
      @log_offset ||= @log_pages.current.offset
      @logs = @query_logs.logs(:order => sort_logs_clause,
                               :offset => @log_offset,
                               :limit => @limit)
      @log_count_by_group = @query_logs.log_count_by_group
      #@log_count_by_group = 0
    end

    # time_bookings list  =======================

    @query_give_logs = false
    @query_give_bookings = true
    tt_retrieve_query

    # group list by date per default // TODO replace this with some kind of user-settings later!
    @query_bookings.group_by ||= "tt_booking_date"

    # overwrite the initial column_names cause if no columns are specified, the Query class uses default values
    # which depend on issues
    @query_bookings.column_names = @query_bookings.column_names || [:tt_booking_date, :comments, :issue, :get_formatted_time]
    #show only the actual users entries from the last 2 weeks
    @query_bookings.filters = {:tt_user => {:operator => "=", :values => [User.current.id.to_s]}, :tt_start_date => {:operator => ">=", :values => [(Time.now-2.weeks).beginning_of_day.to_s]}}

    # temporarily limit the available filters and columns for the view!
    @query_bookings.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_') }
    @query_bookings.available_columns.delete_if { |item| !([:id, :comments, :issue, :user, :project, :tt_booking_date, :get_formatted_time].include? item.name) }

    sort_init(@query_bookings.sort_criteria.empty? ? [['tt_bookings_id', 'desc']] : @query_bookings.sort_criteria)
    tt_sort_update(:sort_bookings, @query_bookings.sortable_columns, "tt_booking_sort")

    if @query_bookings.valid?
      #@limit = per_page_option
      @booking_count = @query_bookings.booking_count
      @booking_pages = Paginator.new self, @booking_count, @limit, params['page_bookings']
      @booking_offset ||= @booking_pages.current.offset
      @bookings = @query_bookings.bookings(:order => sort_bookings_clause,
                                           :offset => @booking_offset,
                                           :limit => @limit)
      @booking_count_by_group = @query_bookings.booking_count_by_group
    end
  end
end