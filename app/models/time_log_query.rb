class TimeLogQuery < Query
  include TtQueryOperators
  include TtQueryConcern

  self.queried_class = TimeLog
  @visibile_permission = :index_tt_logs_list

  self.available_columns = [
      QueryColumn.new(:comments, :caption => :field_tt_comments),
      QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user),
      QueryColumn.new(:tt_log_date, :sortable => "#{TimeLog.table_name}.started_on", :default_order => 'desc', :caption => :field_tt_date, :groupable => "DATE(#{TimeLog.table_name}.started_on)"),
      QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start),
      QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop),
      QueryColumn.new(:get_formatted_bookable_hours, :caption => :field_tt_log_bookable_hours),
  ]

  def auth_values
    add_available_filter 'tt_start_date', :type => :date, :order => 2
    add_available_filter 'tt_log_bookable', :type => :list, :order => 7, :values => [[l(:time_tracker_label_true), 1]]
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
      custom_field_value()
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