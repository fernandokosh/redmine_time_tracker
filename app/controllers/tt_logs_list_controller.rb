class TtLogsListController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_logs_list
  before_filter :authorize_global

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :time_trackers
  include TimeTrackersHelper

  def index
    time_logs_query

    unless User.current.allowed_to_globally?(:tt_edit_time_logs, {})
      @query_logs.filters[:tt_user] = {:operator => "=", :values => [User.current.id.to_s]}
    end

    sort_init(@query_logs.sort_criteria.empty? ? [['tt_log_date', 'desc']] : @query_logs.sort_criteria)
    tt_sort_update(:sort_logs, @query_logs.sortable_columns, "tt_log_sort")

    if @query_logs.valid?
      @limit = per_page_option
      @log_count = @query_logs.log_count
      @log_pages = Paginator.new self, @log_count, @limit, params['page_logs']
      @log_offset ||= @log_pages.current.offset
      @logs = @query_logs.logs(:order => sort_logs_clause,
                          :offset => @log_offset,
                          :limit => @limit)
      @log_count_by_group = @query_logs.log_count_by_group
    end

    render :template => 'tt_logs_list/index', :locals => {:query => @query_logs}
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end