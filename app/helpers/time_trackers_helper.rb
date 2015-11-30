require 'redmine/i18n'
module TimeTrackersHelper
  include Redmine::I18n
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

  def shared_activities
    TimeEntryActivity.shared.all
  end

  def get_activities(project_id)
    if project_id.blank?
      TimeEntryActivity.shared.active.all
    else
      project_from_id(project_id).activities
    end
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

  def time_dist2string(dist_in_min)
    h = dist_in_min / 60
    m = dist_in_min % 60
    "#{h.to_s.rjust(2,'0')}:#{m.to_s.rjust(2,'0')}"
  end

  def time_string4report(ts)
    parts = ts.split(":")
    parts[0] + "h " + parts[1] + "m"
  end

  def user_time_zone
    User.current.time_zone || Time
  end

  def in_user_time_zone(time)
     unless User.current.time_zone.nil?
       time.in_time_zone User.current.time_zone
     else
       time.localtime
     end
  end

  def parse_localised_date_string(date_string)
    1.upto(12) do |i|
      matched = date_string.gsub!(l('date.month_names')[i], l('date.month_names', :locale => :en)[i])
      date_string.gsub!(l('date.abbr_month_names')[i], l('date.abbr_month_names', :locale => :en)[i]) if matched.nil?
    end
    user_time_zone.parse(Date.strptime(date_string, Setting.date_format.presence || l('date.formats.default')).to_s).to_date.to_s
  end

  def parse_localised_time_string(time_string)
    user_time_zone.parse(time_string.gsub(l('time.pm'), 'pm').gsub(l('time.am'), 'am')).strftime("%H:%M")
  end

  def build_timeobj_from_strings(date_string, time_string)
    user_time_zone.parse(date_string + " " + time_string).localtime
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
      query = Query.find(params[:query_id])
      raise ::Unauthorized unless query.visible?
      sess_info = {:filters => query.filters, :group_by => query.group_by, :column_names => query.column_names}
      case query.class.name
        when 'TimeLogQuery'
          session[:tt_user_logs_query] = sess_info
          @query_logs = query.clone
        when 'TimeBookingQuery'
          session[:tt_user_bookings_query] = sess_info
          @query_bookings = query.clone
        when 'ReportQuery'
          session[:tt_user_reports_query] = sess_info
          @query_reports = query.clone
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

  def reports_query
    @query_reports ||= if params[:set_filter] == '3' || session[:tt_user_reports_query].nil?
      query = ReportQuery.new :name => 'x', :filters => {}
      query.build_from_params(params)
      session[:tt_user_reports_query] = {:filters => query.filters, :group_by => query.group_by, :column_names => query.column_names}
      query.clone
    else
      ReportQuery.find_by_id(session[:tt_user_reports_query][:id]) if session[:tt_user_reports_query][:id]
    end || ReportQuery.new(:name => 'x', :filters => session[:tt_user_reports_query][:filters] || {}, :group_by => session[:tt_user_reports_query][:group_by], :column_names => session[:tt_user_reports_query][:column_names])
  end
end
