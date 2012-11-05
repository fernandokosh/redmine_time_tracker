require_dependency 'query'
require_dependency 'project'
require_dependency 'active_record'
require_dependency '../plugins/redmine_time_tracker/app/models/time_booking'
require_dependency '../plugins/redmine_time_tracker/app/models/time_log'

# TODO write a declarative comment
module QueryPatch
  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do

      validate :tt_query_type_is_integer, :on => :update

      alias_method_chain :initialize, :time_tracker
      alias_method_chain :available_filters, :time_tracker
      alias_method_chain :sortable_columns, :time_tracker
      alias_method_chain :available_columns, :time_tracker

      base.add_available_column(QueryColumn.new(:comments, :caption => :field_tt_comments))
      base.add_available_column(QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user))
      base.add_available_column(QueryColumn.new(:tt_booking_date, :sortable => "#{TimeBooking.table_name}.started_on", :caption => :field_tt_date, :groupable => "DATE(#{TimeBooking.table_name}.started_on)"))
      base.add_available_column(QueryColumn.new(:tt_log_date, :sortable => "#{TimeLog.table_name}.started_on", :caption => :field_tt_date, :groupable => "DATE(#{TimeLog.table_name}.started_on)"))
      base.add_available_column(QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start))
      base.add_available_column(QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop))
      base.add_available_column(QueryColumn.new(:get_formatted_time, :caption => :field_tt_time))
      base.add_available_column(QueryColumn.new(:get_formatted_bookable_hours, :caption => :field_tt_log_bookable_hours))
      base.add_available_column(QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :caption => :field_tt_booking_issue, :groupable => "#{Issue.table_name}.subject"))
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    def tt_query_type_is_integer
      self.tt_query_type.is_a? Integer
    end

    def tt_query?
      self.tt_query_type != 0
    end

    # tt_query_types are:
    #       0 => default Redmine Queries
    #       1 => TimeLog Queries
    #       2 => TimeBooking Queries
    def tt_query_type=(type)
      if !self.tt_query? && type != 0 # change from normal redmine query to tt_query-type
        self.filters.delete('status_id') if self.filters
      elsif self.tt_query? && type == 0 # change back from tt_query to standard redmine query
        self.filters ||= {'status_id' => {:operator => "o", :values => [""]}} # reset original values
      end

      write_attribute(:tt_query_type, type)
      # to force a recalculation, we have to set columns and filters "nil"
      @available_columns = nil
      @available_filters = nil
    end

    def initialize_with_time_tracker(attributes=nil, *args)
      initialize_without_time_tracker attributes
      self.filters.delete('status_id') if tt_query?
    end

    # following two methods are a workaround to implement some custom filters to the date-filter without rewriting
    # Query-class and JS-methods for filter-build completely
    def tt_operators_labels
      if tt_query?
        opl = Query.operators_labels.clone
        opl["!*"] = l(:time_tracker_label_this_month)
        opl
      else
        Query.operators_labels
      end
    end

    def tt_operators_by_filter_type
      if tt_query?
        ops = Query.operators_by_filter_type.clone
        ops[:date] = ["=", "><", "t", "w", "!*", "*"]
        ops
      else
        Query.operators_by_filter_type
      end
    end

    def sortable_columns_with_time_tracker
      if tt_query?
        {'tt_booking_id' => "#{TimeBooking.table_name}.id", 'tt_log_id' => "#{TimeLog.table_name}.id"}.merge(available_columns.inject({}) { |h, column|
          h[column.name.to_s] = column.sortable
          h
        })
      else
        sortable_columns_without_time_tracker
      end
    end

    # we have to remove our new columns from the normal query-column-list, cause if we don't do that,
    # the normal filter-menu at the issues-view will show columns which will lead in an error if used
    def available_columns_with_time_tracker
      @available_columns = available_columns_without_time_tracker
      case tt_query_type
        when 1
          @available_columns.delete_if { |item| !([:id, :user, :tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :comments, :get_formatted_bookable_hours].include? item.name) }
        when 2
          @available_columns.delete_if { |item| !([:id, :user, :project, :tt_booking_date, :get_formatted_start_time, :get_formatted_stop_time, :issue, :comments, :get_formatted_time].include? item.name) }
        else # show default redmine query-columns and remove the patched in ones
          @available_columns.delete_if { |item| [:issue, :comments, :user, :tt_booking_date, :tt_log_date, :get_formatted_start_time, :get_formatted_stop_time, :get_formatted_time, :get_formatted_bookable_hours].include? item.name }
      end
      @available_columns
    end

    # we also have to keep the filters clean in normal mode
    def available_filters_with_time_tracker
      # only list the new filters if the time_tracker flag is set
      return available_filters_without_time_tracker unless tt_query?

      # speedup for recursive calls, so we only calc the content for the query once!
      return @available_filters if @available_filters

      @available_filters = available_filters_without_time_tracker
      @available_filters.clear # remove all the redmine filters

      # use raw Query as template to get the content for two complex fields without copying the source
      tq = Query.new

      case tt_query_type
        when 1 # TimeLogs Query
          @available_filters['tt_log_start_date'] = {:type => :date, :order => 2}
          @available_filters["tt_log_bookable"] = {:type => :list, :order => 7, :values => [[l(:time_tracker_label_true), 1]]}
          @available_filters['tt_user'] = tq.available_filters_without_time_tracker["author_id"].clone unless tq.available_filters_without_time_tracker["author_id"].nil?
        when 2 # TimeBookings Query
          @available_filters['tt_booking_project'] = tq.available_filters_without_time_tracker["project_id"].clone unless tq.available_filters_without_time_tracker["project_id"].nil?
          @available_filters['tt_booking_start_date'] = {:type => :date, :order => 2}
          @available_filters['tt_booking_issue'] = {:type => :list, :order => 4, :values => Issue.visible.all.collect { |s| [s.subject, s.id.to_s] }}
          @available_filters['tt_user'] = tq.available_filters_without_time_tracker["author_id"].clone unless tq.available_filters_without_time_tracker["author_id"].nil?
        else
          #change nothing. default is to handle standard redmine filters
      end

      @available_filters.each do |field, options|
        options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
      end

      @available_filters
    end

    # Returns the bookings count
    def booking_count
      # TODO refactor includes
      TimeBooking.visible.
          includes([:project, {:time_entry => :issue}, {:time_log => :user}]).
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
              includes([:project, {:time_entry => :issue}, {:time_log => :user}]).
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
      raise StatementInvalid.new(e.message)
    end

    # Returns the bookings
    # Valid options are :order, :offset, :limit, :include, :conditions
    def bookings(options={})
      order_option = [group_by_sort_order, options[:order]].reject { |s| s.blank? }.join(',')
      order_option = nil if order_option.blank?

      TimeBooking.visible.
          includes([:project, {:time_entry => :issue}, {:time_log => :user}]).
          where(statement).
          order(order_option).
          limit(options[:limit]).
          offset(options[:offset])

    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

    # same things for logs === later we should combine both parts to more flexible/general methods
    # even better would be to generalize the whole Query class from redmine

    # Returns the logs count
    def log_count
      TimeLog.visible.
          includes(:user).
          where(statement).
          count(:id)
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
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
      raise StatementInvalid.new(e.message)
    end

    # Returns the logs
    def logs(options={})
      order_option = [group_by_sort_order, options[:order]].reject { |s| s.blank? }.join(',')
      order_option = nil if order_option.blank?

      TimeLog.visible.
          includes(:user, :time_bookings).
          where(statement).
          order(order_option).
          limit(options[:limit]).
          offset(options[:offset])

    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
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

    def sql_for_tt_XX_start_date_field(table, operator, value)
      t = case table
            when "log"
              TimeLog.table_name
            when "booking"
              TimeBooking.table_name
            else
              nil
          end

      if t.nil?
        ""
      else
        case operator
          when "="
            "DATE(#{t}.started_on) = '#{Time.parse(value[0]).to_date}'"
          when "><"
            "DATE(#{t}.started_on) >= '#{Time.parse(value[0]).to_date}' AND DATE(#{t}.started_on) <= '#{Time.parse(value[1]).to_date}'"
          when "t"
            "DATE(#{t}.started_on) = '#{Time.now.localtime.to_date}'"
          when "w"
            "DATE(#{t}.started_on) >= '#{Time.now.localtime.beginning_of_week.to_date}' AND DATE(#{t}.started_on) <= '#{Time.now.localtime.end_of_week.to_date}'"
          # following filter is used as workaround for custom-filters. so the logic implemented here is not "none"!
          # instead it represents "this month"
          when "!*"
            "DATE(#{t}.started_on) >= '#{Time.now.localtime.beginning_of_month.to_date}' AND DATE(#{t}.started_on) <= '#{Time.now.localtime.end_of_month.to_date}'"
          when "*"
            "DATE(#{t}.started_on) IS NOT NULL"
          else
            "#{t}.started_on >= '#{(Time.now.localtime-2.weeks).beginning_of_day.to_date}'"
        end
      end
    end

    def sql_for_tt_log_start_date_field(table, operator, value)
      sql_for_tt_XX_start_date_field("log", operator, value)
    end

    def sql_for_tt_booking_start_date_field(table, operator, value)
      sql_for_tt_XX_start_date_field("booking", operator, value)
    end

    def sql_for_tt_booking_issue_field(field, operator, value)
      sql = "( #{Issue.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
      unless operator == "="
        sql << " OR #{Issue.table_name}.id IS NULL"
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
            "#{TimeLog.table_name}.bookable = 't'"
          else
            "#{TimeLog.table_name}.bookable = 'f'"
          end
        when "!"
          if value[0] == "1"
            "#{TimeLog.table_name}.bookable = 'f'"
          else
            "#{TimeLog.table_name}.bookable = 't'"
          end
        else
          ""
      end
    end
  end
end

Query.send(:include, QueryPatch)