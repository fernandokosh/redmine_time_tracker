class TtBookingsListController < ApplicationController

  menu_item :time_tracker_menu_tab_bookings_list
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
  helper :time_bookings_sidebar

  def index
    query_from_id
    time_bookings_query

    unless User.current.allowed_to_globally?(:tt_edit_bookings, {})
      @query_bookings.filters[:tt_user] = {:operator => "=", :values => [User.current.id.to_s]}
    end

    sort_init(@query_bookings.sort_criteria.empty? ? [['tt_booking_date', 'desc']] : @query_bookings.sort_criteria)
    tt_sort_update(:sort_bookings, @query_bookings.sortable_columns, "tt_booking_sort")

    if @query_bookings.valid?
      @limit = per_page_option

      @booking_count = @query_bookings.bookings.count
      @booking_pages = Paginator.new @booking_count, @limit, params['page'], 'page'
      @offset ||= @booking_pages.offset
      @bookings = @query_bookings.bookings(:order => sort_bookings_clause,
                                           :offset => @offset,
                                           :limit => @limit)
      @booking_count_by_group = @query_bookings.booking_count_by_group
    end

    render :template => 'tt_bookings_list/index', :locals => {:query => @query_bookings}
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def check_settings_for_ajax
    flash[:error] = l(:force_auth_requires_rest_api) if Setting.login_required? && !Setting.rest_api_enabled?
  end
end