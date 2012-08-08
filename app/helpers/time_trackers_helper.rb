module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  def user_from_id(user_id)
    User.where(:id => user_id).first
  end

  def get_current_time_tracker
    current = TimeTracker.where(:user_id => User.current.id).first
    current.nil? ? TimeTracker.new : current
  end

  def paginate_array(array, page)
    limit = 15 # 15 items per page
    page = 1 if page == 0
    limit * (page - 1) > array.size - 1 ? offset = 0 : offset = limit * (page - 1)
    offset + limit >= array.size ? stop_loop = array.size-1 : stop_loop = offset + limit - 1
               # filling the array for the view
    erg = []
    for i in offset..stop_loop
      erg.push(array[i])
    end
    {:limit => limit, :page => page, :arr => erg}
  end

  def tt_column_header(column, sort_arg)
    column.sortable ? tt_sort_header_tag(sort_arg, column.name.to_s, :caption => column.caption,
                                         :default_order => column.default_order) :
        content_tag('th', h(column.caption))
  end

  def sort_logs_clause()
    @sort_logs_criteria.to_sql
  end

  def sort_bookings_clause()
    @sort_bookings_criteria.to_sql
  end

  def calendar_for_tt(field_id)
    include_calendar_headers_tags
    image_tag("calendar.png", {:id => "#{field_id}_trigger", :class => "calendar-trigger"}) +
        javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger', onUpdate : updateTTControllerForm });")
  end

  def tt_retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:tt_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
      #elsif params[:set_filter]
    elsif params[:set_filter] == "1" && !@query_give_logs && !@query_give_bookings ||
        params[:set_filter] == "2" && @query_give_logs && !@query_give_bookings ||
        params[:set_filter] == "3" && !@query_give_logs && @query_give_bookings ||
        session[:tt_query].nil? && !@query_give_logs && !@query_give_bookings ||
        session[:tt_user_logs_query].nil? && @query_give_logs ||
        session[:tt_user_bookings_query].nil? && @query_give_bookings
      # Give it a name, required to be valid
      @query = Query.new(:tt_query => true, :name => "_")
      build_query_from_params
      sess_info = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}

      if params[:set_filter] == "1" || session[:tt_query].nil? && !@query_give_logs && !@query_give_bookings # admins log-view
        session[:tt_query] = sess_info
      elsif params[:set_filter] == "2" || session[:tt_user_logs_query].nil? && @query_give_logs # overview list time_logs
        session[:tt_user_logs_query] = sess_info
        @query_logs = @query.clone
      elsif params[:set_filter] == "3" || session[:tt_user_bookings_query].nil? && @query_give_bookings # overview list time_bookings
        session[:tt_user_bookings_query] = sess_info
        @query_bookings = @query.clone
      end
    elsif @query_give_logs && !@query_give_bookings # get time_logs for overview page
      @query_logs = Query.find_by_id(session[:tt_user_logs_query][:id]) if session[:tt_user_logs_query][:id]
      @query_logs ||= Query.new(:tt_query => true, :name => "_", :filters => session[:tt_user_logs_query][:filters], :group_by => session[:tt_user_logs_query][:group_by], :column_names => session[:tt_user_logs_query][:column_names])
    elsif !@query_give_logs && @query_give_bookings # get time_bookings for overview page
      @query_bookings = Query.find_by_id(session[:tt_user_bookings_query][:id]) if session[:tt_user_bookings_query][:id]
      @query_bookings ||= Query.new(:tt_query => true, :name => "_", :filters => session[:tt_user_bookings_query][:filters], :group_by => session[:tt_user_bookings_query][:group_by], :column_names => session[:tt_user_bookings_query][:column_names])
    else # get query for admins log-view
         # retrieve from session
      @query = Query.find_by_id(session[:tt_query][:id]) if session[:tt_query][:id]
      @query ||= Query.new(:tt_query => true, :name => "_", :filters => session[:tt_query][:filters], :group_by => session[:tt_query][:group_by], :column_names => session[:tt_query][:column_names])
    end
    @query.tt_query = true if @query
    @query_logs.tt_query = true if @query_logs
    @query_bookings.tt_query = true if @query_bookings
  end

  def time_logs_query
    @query_give_logs = true
    @query_give_bookings = false
    tt_retrieve_query
    # overwrite the initial column_names cause if no columns are specified, the Query class uses default values
    # which depend on issues
    @query_logs.column_names = @query_logs.column_names || [:tt_log_date, :comments, :get_formatted_bookable_hours]
    @query_logs.filters = {:tt_user => {:operator => "=", :values => [User.current.id.to_s]}}

    # temporarily limit the available filters and columns for the view!
    @query_logs.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_') }
    @query_logs.available_columns.delete_if { |item| !([:id, :comments, :user, :tt_log_date, :get_formatted_bookable_hours].include? item.name) }
  end
end
