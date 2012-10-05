module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  def user_from_id(user_id)
    User.where(:id => user_id).first
  end

  def project_from_id(project_id)
    Project.where(:id => project_id).first
  end

  def time_dist2string(dist)
    h = dist / 3600
    m = (dist - h*3600) / 60
    s = dist - (h*3600 + m*60)
    h<10 ? h="0#{h}" : h = h.to_s
    m<10 ? m="0#{m}" : m = m.to_s
    s<10 ? s="0#{s}" : s = s.to_s
    h + ":" + m + ":" + s
  end

  def time_string4report(ts)
    parts = ts.split(":")
    parts[0] + "h " + parts[1] + "m"
  end

  def get_current_time_tracker
    current = TimeTracker.where(:user_id => User.current.id).first
    current.nil? ? TimeTracker.new : current
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

  def time_string2hour(str)
    sec = 0
    if str.match(/\d\d?:\d\d?:\d\d?/) #parse general input form hh:mm:ss
      arr = str.strip.split(':')
      sec = arr[0].to_i * 3600 + arr[1].to_i * 60 + arr[2].to_i
    elsif str.match(/\d\d?:\d\d?/) #parse general input form hh:mm
      arr = str.strip.split(':')
      sec = arr[0].to_i * 3600 + arr[1].to_i * 60
    else
      # more flexible parsing for inputs like:  12d 23sec 5min
      time_factor = {:s => 1, :sec => 1, :m => 60, :min => 60, :h => 3600, :d => 86400}
      str.partition(/\A\d+\s*\D+/).each do |item|
        item=item.strip
        item.match(/\d+/).nil? ? num = nil : num = item.match(/\d+/)[0].to_i
        item.match(/\D+/).nil? ? fac = nil : fac = item.match(/\D+/)[0].strip.downcase.to_sym
        if time_factor.has_key?(fac)
          sec += num * time_factor.fetch(fac)
        end
      end
    end
    sec.to_f / 3600
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
    @query_logs.column_names = @query_logs.column_names || [:tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours]
    @query_logs.filters = {:tt_user => {:operator => "=", :values => [User.current.id.to_s]}}

    # temporarily limit the available filters and columns for the view!
    @query_logs.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_') }
    @query_logs.available_columns.delete_if { |item| !([:id, :user, :tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours].include? item.name) }
  end

  def time_bookings_query
    @query_give_logs = false
    @query_give_bookings = true
    tt_retrieve_query

    # overwrite the initial column_names cause if no columns are specified, the Query class uses default values
    # which depend on issues
    @query_bookings.column_names = @query_bookings.column_names || [:project, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time]

    # temporarily limit the available filters and columns for the view!
    @query_bookings.available_filters.delete_if { |key, value| !key.to_s.start_with?('tt_') }
    @query_bookings.available_columns.delete_if { |item| !([:id, :user, :project, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time].include? item.name) }
  end
end
