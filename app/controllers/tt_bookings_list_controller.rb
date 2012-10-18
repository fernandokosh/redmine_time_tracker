class TtBookingsListController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_bookings_list
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :time_trackers
  include TimeTrackersHelper

  def index
    time_bookings_query

    unless User.current.allowed_to_globally?(:tt_edit_bookings, {})
      @query_bookings.filters[:tt_user] = {:operator => "=", :values => [User.current.id.to_s]}
    end

    sort_init(@query_bookings.sort_criteria.empty? ? [['tt_booking_date', 'desc']] : @query_bookings.sort_criteria)
    tt_sort_update(:sort_bookings, @query_bookings.sortable_columns, "tt_booking_sort")

    if @query_bookings.valid?
      @limit = per_page_option

      @booking_count = @query_bookings.booking_count
      @booking_pages = Paginator.new self, @booking_count, @limit, params['page']
      @offset ||= @booking_pages.current.offset
      @bookings = @query_bookings.bookings(:order => sort_bookings_clause,
                                           :offset => @offset,
                                           :limit => @limit)
      @booking_count_by_group = @query_bookings.booking_count_by_group
    end

    render :template => 'tt_bookings_list/index', :locals => {:query => @query_bookings}
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end