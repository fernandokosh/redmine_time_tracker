class TimeListController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_list
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query
    # overwrite the initial column_names cause if no columns are specified, the Query class uses default values
    # which depend on issues
    @query.column_names = @query.column_names || [:id, :time_log_id, :time_entry_id, :comments, :user, :project]

    # temporarily limit the available filters for the view!
    @query.available_filters.delete_if { |key,value| !key.to_s.start_with?('tt_') }

    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
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

      render :template => 'time_list/index'
    else
      render :template => 'time_list/index'
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end