class TtBookingsListController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_bookings_list
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include TimeTrackersHelper

  def index
    tt_retrieve_query
    # overwrite the initial column_names cause if no columns are specified, the Query class uses default values
    # which depend on issues
    @query.column_names = @query.column_names || [:project, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time]

    # temporarily limit the available filters and columns for the view!
    @query.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_') }
    @query.available_columns.delete_if { |item| !([:id, :user,:project, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time].include? item.name) }

    sort_init(@query.sort_criteria.empty? ? [['tt_booking_date', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @limit = per_page_option

      @booking_count = @query.booking_count
      @booking_pages = Paginator.new self, @booking_count, @limit, params['page']
      @offset ||= @booking_pages.current.offset
      @bookings = @query.bookings(:order => sort_clause,
                                  :offset => @offset,
                                  :limit => @limit)
      @booking_count_by_group = @query.booking_count_by_group
    end

    render :template => 'tt_bookings_list/index'
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end