class TimeBookingQuery < Query
  include TtQueryOperators

  self.queried_class = TimeBooking

  self.available_columns = [
      QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
      QueryColumn.new(:activity, :caption => :field_tt_booking_activity, :sortable => "#{TimeEntryActivity.table_name}.name", :groupable => "#{TimeEntryActivity.table_name}.name"),
      QueryColumn.new(:comments, :caption => :field_tt_comments),
      QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user),
      QueryColumn.new(:tt_booking_date, :sortable => "#{TimeBooking.table_name}.started_on", :default_order => 'desc', :caption => :field_tt_date, :groupable => "DATE(#{TimeBooking.table_name}.started_on)"),
      QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start),
      QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop),
      QueryColumn.new(:get_formatted_time, :caption => :field_tt_time),
      QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :caption => :field_tt_booking_issue, :groupable => "#{Issue.table_name}.subject"),
  ]

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :index_tt_bookings_list, *args)
    user_id = user.logged? ? user.id : 0

    includes(:project).where("(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id)
  }

  def visible?(user=User.current)
    (project.nil? || user.allowed_to?(:index_tt_bookings_list, project)) && (self.is_public? || self.user_id == user.id)
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

    add_available_filter 'tt_booking_start_date', :type => :date, :order => 2
    add_available_filter 'tt_booking_issue', :type => :list, :order => 4, :values => Issue.visible.all.collect { |s| [s.subject, s.id.to_s] }
    add_available_filter 'tt_booking_activity', :type => :list, :order => 4, :values => help.get_activities('').map { |s| [s.name, s.name] }

    if project.nil?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("tt_booking_project", :type => :list, :values => project_values) unless project_values.empty?
    end

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect { |s| [s.name, s.id.to_s] }
    add_available_filter('tt_user', :type => :list, :values => author_values) unless author_values.empty?
  end

  def default_columns_names
    [:project, :activity, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time]
  end

  # Returns the bookings count
  def booking_count
    # TODO refactor includes
    TimeBooking.visible.
        includes([:project, {:time_entry => :issue}, {:time_entry => :activity}, {:time_log => :user}]).
        where(statement).
        count(:id)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the bookings count by group or nil if query is not grouped
  def booking_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        # for some reason including the :project will result in an "ambiguous column" - error if we try to group by
        # "project" and additionally filter by issue. so we have to use a small workaround
        # todo figure out the 'rails-way' to avoid ambiguous columns
        gbs = group_by_statement
        gbs = "#{Project.table_name}.name" if gbs == "project"
        r = TimeBooking.visible.
            includes([:project, {:time_entry => :issue}, {:time_entry => :activity}, {:time_log => :user}]).
            group(gbs).
            where(statement).
            count(:id)
      rescue ActiveRecord::RecordNotFound
        r = {nil => booking_count}
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

  # Returns the bookings
  # Valid options are :order, :offset, :limit, :include, :conditions
  def bookings(options={})
    group_by_order = (group_by_sort_order || '').strip
    options[:order].unshift group_by_order unless options[:order].map { |opt| opt.gsub('asc', '').gsub('desc', '').strip }.include? group_by_order.gsub('asc', '').gsub('desc', '').strip
    order_option = options[:order].reject { |s| s.blank? }.join(',')
    order_option = nil if order_option.blank?

    TimeBooking.visible.
        includes([:project, {:time_entry => :issue}, {:time_entry => :activity}, {:time_log => :user}]).
        where(statement).
        order(order_option).
        limit(options[:limit]).
        offset(options[:offset])

  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # sql statements for where clauses have to be in an "sql_for_#{filed-name}_field" method
  # so we have to implement some where-clauses for every new filter here
  def sql_for_tt_booking_project_field(field, operator, value)
    if value.delete('mine')
      value += User.current.memberships.map(&:project_id).map(&:to_s)
    end
    if operator == "="
      "( #{TimeBooking.table_name}.project_id IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
    else
      "( #{TimeBooking.table_name}.project_id NOT IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") OR #{TimeBooking.table_name}.project_id IS NULL )"
    end
  end

  def sql_for_tt_booking_start_date_field(field, operator, value)
    case operator
      when "="
        "DATE(#{TimeBooking.table_name}.started_on) = '#{Time.parse(value[0]).to_date}'"
      when "><"
        "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.parse(value[0]).to_date}' AND DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.parse(value[1]).to_date}'"
      when "t"
        "DATE(#{TimeBooking.table_name}.started_on) = '#{Time.now.localtime.to_date}'"
      when "w"
        "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.now.localtime.beginning_of_week.to_date}' AND DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.now.localtime.end_of_week.to_date}'"
      # following filter is used as workaround for custom-filters. so the logic implemented here is not "none"!
      # instead it represents "this month"
      when "!*"
        "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.now.localtime.beginning_of_month.to_date}' AND DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.now.localtime.end_of_month.to_date}'"
      when "*"
        "DATE(#{TimeBooking.table_name}.started_on) IS NOT NULL"
      else
        "#{TimeBooking.table_name}.started_on >= '#{(Time.now.localtime-2.weeks).beginning_of_day.to_date}'"
    end
  end

  def sql_for_tt_booking_issue_field(field, operator, value)
    sql = "( #{Issue.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") "
    if operator == "!"
      sql << " OR #{Issue.table_name}.id IS NULL)"
    else
      sql << ")"
    end
  end

  def sql_for_tt_user_field(field, operator, value)
    if value.delete('me')
      value += User.current.id.to_s.to_a
    end
    "( #{User.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
  end

  def sql_for_tt_booking_activity_field(field, operator, value)
    "( #{TimeEntryActivity.table_name}.name #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
  end
end