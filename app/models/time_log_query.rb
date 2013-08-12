class TimeLogQuery < Query
  include TtQueryOperators

  self.queried_class = TimeLog

  self.available_columns = [
      QueryColumn.new(:comments, :caption => :field_tt_comments),
      QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user),
      QueryColumn.new(:tt_log_date, :sortable => "#{TimeLog.table_name}.started_on", :default_order => 'desc', :caption => :field_tt_date, :groupable => "DATE(#{TimeLog.table_name}.started_on)"),
      QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start),
      QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop),
      QueryColumn.new(:get_formatted_bookable_hours, :caption => :field_tt_log_bookable_hours),
  ]

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :index_tt_logs_list, *args)
    user_id = user.logged? ? user.id : 0

    includes(:project).where("(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id)
  }

  def visible?(user=User.current)
    (project.nil? || user.allowed_to?(:index_tt_logs_list, project)) && (self.is_public? || self.user_id == user.id)
  end

  def initialize_available_filters
    principals = []

    if project
      principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        principals += Principal.member_of(subprojects)
      end
    else
      if all_projects.any?
        principals += Principal.member_of(all_projects)
      end
    end
    principals.uniq!
    principals.sort!
    users = principals.select { |p| p.is_a?(User) }

    add_available_filter 'tt_log_start_date', :type => :date, :order => 2
    add_available_filter 'tt_log_bookable', :type => :list, :order => 7, :values => [[l(:time_tracker_label_true), 1]]

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect { |s| [s.name, s.id.to_s] }
    add_available_filter('tt_user', :type => :list, :values => author_values) unless author_values.empty?
  end

  def default_columns_names
    [:tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours]
  end

  # Returns the logs count
  def log_count
    TimeLog.visible.
        includes(:user).
        where(statement).
        count(:id)
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the logs count by group or nil if query is not grouped
  def log_count_by_group
    r = nil
    if grouped?
      begin
        gbs = group_by_statement
        r = TimeLog.visible.
            includes(:user).
            group(gbs).
            where(statement).
            count(:id)
      rescue ActiveRecord::RecordNotFound
        r = {nil => log_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) { |h, k| h[c.custom_field.cast_value(k)] = r[k]; h }
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the logs
  def logs(options={})
    group_by_order = (group_by_sort_order || '').strip
    options[:order].unshift group_by_order unless options[:order].map { |opt| opt.gsub('asc', '').gsub('desc', '').strip }.include? group_by_order.gsub('asc', '').gsub('desc', '').strip
    order_option = options[:order].reject { |s| s.blank? }.join(',')
    order_option = nil if order_option.blank?

    TimeLog.visible.
        includes(:user, :time_bookings).
        where(statement).
        order(order_option).
        limit(options[:limit]).
        offset(options[:offset])

  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  def sql_for_tt_log_start_date_field(field, operator, value)
    case operator
      when "="
        "DATE(#{TimeLog.table_name}.started_on) = '#{Time.parse(value[0]).to_date}'"
      when "><"
        "DATE(#{TimeLog.table_name}.started_on) >= '#{Time.parse(value[0]).to_date}' AND DATE(#{TimeLog.table_name}.started_on) <= '#{Time.parse(value[1]).to_date}'"
      when "t"
        "DATE(#{TimeLog.table_name}.started_on) = '#{Time.now.localtime.to_date}'"
      when "w"
        "DATE(#{TimeLog.table_name}.started_on) >= '#{Time.now.localtime.beginning_of_week.to_date}' AND DATE(#{TimeLog.table_name}.started_on) <= '#{Time.now.localtime.end_of_week.to_date}'"
      # following filter is used as workaround for custom-filters. so the logic implemented here is not "none"!
      # instead it represents "this month"
      when "!*"
        "DATE(#{TimeLog.table_name}.started_on) >= '#{Time.now.localtime.beginning_of_month.to_date}' AND DATE(#{TimeLog.table_name}.started_on) <= '#{Time.now.localtime.end_of_month.to_date}'"
      when "*"
        "DATE(#{TimeLog.table_name}.started_on) IS NOT NULL"
      else
        "#{TimeLog.table_name}.started_on >= '#{(Time.now.localtime-2.weeks).beginning_of_day.to_date}'"
    end
  end

  def sql_for_tt_user_field(field, operator, value)
    if value.delete('me')
      value += User.current.id.to_s.to_a
    end
    "( #{User.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
  end

  def sql_for_tt_log_bookable_field(field, operator, value = ["1"])
    case operator
      when "="
        if value[0] == "1"
          "#{TimeLog.table_name}.bookable = " + connection.quoted_true
        else
          "#{TimeLog.table_name}.bookable = " + connection.quoted_false
        end
      when "!"
        if value[0] == "1"
          "#{TimeLog.table_name}.bookable = " + connection.quoted_false
        else
          "#{TimeLog.table_name}.bookable = " + connection.quoted_true
        end
      else
        ""
    end
  end
end