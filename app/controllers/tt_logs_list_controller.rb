class TtLogsListController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs_list
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
    @query.column_names = @query.column_names || [:tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours]
    #@query.filters = {:tt_bookable => {:operator => "=", :values => [User.current.id.to_s]}}

    # temporarily limit the available filters and columns for the view!
    @query.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_log_') && !key.to_s.starts_with?('tt_user') }
    @query.available_columns.delete_if { |item| !([:id, :user, :tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours].include? item.name) }

    sort_init(@query.sort_criteria.empty? ? [['tt_log_date', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @limit = per_page_option
      @log_count = @query.log_count
      @log_pages = Paginator.new self, @log_count, @limit, params['page_logs']
      @log_offset ||= @log_pages.current.offset
      @logs = @query.logs(:order => sort_clause,
                          :offset => @log_offset,
                          :limit => @limit)
      @log_count_by_group = @query.log_count_by_group
    end

    render :template => 'tt_logs_list/index'
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end