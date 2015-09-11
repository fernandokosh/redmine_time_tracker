class ReportQuery < Query
  include TtQueryOperators
  include TtQueryConcern

  self.queried_class = TimeBooking
  @visible_permission = :index_tt_bookings_list

  self.available_columns = [
      QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Project.table_name}.name"),
      QueryColumn.new(:activity, :caption => :field_tt_booking_activity, :sortable => "#{TimeEntryActivity.table_name}.name", :groupable => "#{TimeEntryActivity.table_name}.name"),
      QueryColumn.new(:comments, :caption => :field_tt_comments),
      QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user),
      QueryColumn.new(:tt_booking_date, :sortable => "#{TimeBooking.table_name}.started_on", :default_order => 'desc', :caption => :field_tt_date, :groupable => "DATE(#{TimeBooking.table_name}.started_on)"),
      QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start),
      QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop),
      QueryColumn.new(:get_formatted_time, :caption => :field_tt_time),
      QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :caption => :field_tt_booking_issue, :groupable => "#{Issue.table_name}.subject"),
      QueryColumn.new(:fixed_version, :sortable => lambda {Version.fields_for_order_statement}, :groupable => "#{Version.table_name}.name"),
  ]

  def auth_values
    add_available_filter 'tt_start_date', :type => :date, :order => 2
    add_available_filter 'tt_booking_issue', :type => :list, :order => 4, :values => Issue.visible.all.collect { |s| [s.subject, s.id.to_s] }
    add_available_filter 'tt_booking_activity', :type => :list, :order => 4, :values => help.shared_activities.map { |s| [s.name, s.name] }

    project_values = []
    if project.nil?
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("tt_booking_project", :type => :list, :values => project_values) unless project_values.empty?
    end

    versions = []
    if project
      versions = project.shared_versions.all
    else
      # TODO: find a way to get shared_versions without killing the db
      versions = Project.visible.joins(:versions).all.flat_map { |project| project.shared_versions.all }
      versions.uniq!
    end

    if versions.any?
      add_available_filter "tt_booking_fixed_version",
                           :type => :list_optional,
                           :values => versions.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s] }.sort
    end
  end



  def default_columns_names
    [:project, :activity, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time]
  end

  # Returns the bookings count
  def booking_count
    # TODO refactor includes
    TimeBooking.visible.
        includes(:project, {:time_entry => [{:issue => :fixed_version}, :activity]}, {:time_log => :user}).
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
        r = TimeBooking.visible.
            includes(:project, {:time_entry => [{:issue => :fixed_version}, :activity]}, {:time_log => :user}).
            where(statement).
            group(group_by_statement).
            count(:id)
      rescue ActiveRecord::RecordNotFound
        r = {nil => booking_count}
      end
      custom_field_value()
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the bookings
  # Valid options are :order, :offset, :limit, :include, :conditions
  def bookings(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    scope = TimeBooking.visible.
        includes([:project, {:time_entry => [{:issue => :fixed_version}, :activity]}, {:time_log => :user}]).
        where(statement).
        where(options[:conditions]).
        order(order_option).
        limit(options[:limit]).
        offset(options[:offset])

    scope.all
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
      "( #{TimeBooking.table_name}.project_id IN (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") )"
    else
      "( #{TimeBooking.table_name}.project_id NOT IN (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") OR #{TimeBooking.table_name}.project_id IS NULL )"
    end
  end

  def sql_for_tt_booking_issue_field(field, operator, value)
    sql = "( #{Issue.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") "
    if operator == "!"
      sql << " OR #{Issue.table_name}.id IS NULL)"
    else
      sql << ")"
    end
  end


  def sql_for_tt_booking_activity_field(field, operator, value)
    "( #{TimeEntryActivity.table_name}.name #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") )"
  end

  def sql_for_tt_booking_fixed_version_field(field, operator, value)
    if operator == "="
      "( #{Issue.table_name}.fixed_version_id IN (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") )"
    else
      "( #{Issue.table_name}.fixed_version_id NOT IN (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ") OR #{Issue.table_name}.fixed_version_id IS NULL )"
    end
  end
end
