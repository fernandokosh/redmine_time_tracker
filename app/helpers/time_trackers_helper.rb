module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.visible.where(:id => issue_id).first
  end

  def user_from_id(user_id)
    User.where(:id => user_id).first
  end

  def project_from_id(project_id)
    Project.visible.where(:id => project_id).first
  end

  def activity_from_id(activity_id)
    Enumeration.find(activity_id)
  end

  def permission_checker(permission_list, context, global = false)
    return true if User.current.admin?
    flag = false
    permission_list.each do |permission|
      if global
        flag ||= User.current.allowed_to_globally?(permission, {})
      else
        flag ||= User.current.allowed_to?(permission, context)
      end
    end
    flag
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
    if column.sortable
      tt_sort_header_tag sort_arg, column.name.to_s, :caption => column.caption, :default_order => column.default_order
    else
      content_tag('th', h(column.caption))
    end
  end

  def tt_sort_header_tag(sort_arg, column, options = {})
    caption = options.delete(:caption) || column.to_s.humanize
    default_order = options.delete(:default_order) || 'asc'
    options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]
    content_tag('th', tt_sort_link(sort_arg, column, caption, default_order), options)
  end

  def tt_sort_link(sort_arg, column, caption, default_order)
    css, order = nil, default_order

    tt_sort_criteria = @sort_logs_criteria if sort_arg == :sort_logs
    tt_sort_criteria = @sort_bookings_criteria if sort_arg == :sort_bookings
    if column.to_s == tt_sort_criteria.first_key
      if tt_sort_criteria.first_asc?
        css = 'sort asc'
        order = 'desc'
      else
        css = 'sort desc'
        order = 'asc'
      end
    end
    caption = column.to_s.humanize unless caption

    sort_options = { sort_arg => tt_sort_criteria.add(column.to_s, order).to_param }
    url_options = params.merge(sort_options)

    # Add project_id to url_options
    url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

    link_to_content_update(h(caption), url_options, :class => css)
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


  def query_from_id
    unless params[:query_id].blank?
      query = Query.find(params[:query_id], :conditions => "project_id IS NULL")
      raise ::Unauthorized unless query.visible?
      sess_info = {:filters => query.filters, :group_by => query.group_by, :column_names => query.column_names}
      case query.class.queried_class.name
        when 'TimeLog'
          session[:tt_user_logs_query] = sess_info
          @query_logs = query.clone
        when 'TimeBooking'
          session[:tt_user_bookings_query] = sess_info
          @query_bookings = query.clone
      end
      sort_clear
    end
  end

  def time_logs_query
    @query_logs ||= if params[:set_filter] == '2' || session[:tt_user_logs_query].nil?
      query = TimeLogQuery.new :name => 'x', :filters => {}
      query.build_from_params(params)
      session[:tt_user_logs_query] = {:filters => query.filters, :group_by => query.group_by, :column_names => query.column_names}
      query.clone
    else
      TimeLogQuery.find_by_id(session[:tt_user_logs_query][:id]) if session[:tt_user_logs_query][:id]
    end || TimeLogQuery.new(:name => 'x', :filters => session[:tt_user_logs_query][:filters] || {}, :group_by => session[:tt_user_logs_query][:group_by], :column_names => session[:tt_user_logs_query][:column_names])
  end

  def time_bookings_query
    @query_bookings ||= if params[:set_filter] == '3' || session[:tt_user_bookings_query].nil?
      query = TimeBookingQuery.new :name => 'x', :filters => {}
      query.build_from_params(params)
      session[:tt_user_bookings_query] = {:filters => query.filters, :group_by => query.group_by, :column_names => query.column_names}
      query.clone
    else
      TimeBookingQuery.find_by_id(session[:tt_user_bookings_query][:id]) if session[:tt_user_bookings_query][:id]
    end || TimeBookingQuery.new(:name => 'x', :filters => session[:tt_user_bookings_query][:filters] || {}, :group_by => session[:tt_user_bookings_query][:group_by], :column_names => session[:tt_user_bookings_query][:column_names])
  end
end
