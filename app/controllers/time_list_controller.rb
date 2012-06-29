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
    @query.filters.delete("status_id")
    @query.filters.delete("tracker_id")

    @query.group_by=nil

    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @limit = per_page_option

      #@issue_count = @query.issue_count
      #@issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      #@offset ||= @issue_pages.current.offset
      #@issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
      #                        :order => sort_clause,
      #                        :offset => @offset,
      #                        :limit => @limit)
      #@issue_count_by_group = @query.issue_count_by_group

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