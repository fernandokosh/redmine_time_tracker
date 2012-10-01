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

      alias_method_chain :initialize, :time_tracker
      alias_method_chain :available_filters, :time_tracker
      alias_method_chain :sortable_columns, :time_tracker
      alias_method_chain :available_columns, :time_tracker
      alias_method_chain :group_by_sort_order, :time_tracker

      base.add_available_column(QueryColumn.new(:comments, :caption => :field_tt_comments))
      base.add_available_column(QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user))
      base.add_available_column(QueryColumn.new(:tt_booking_date, :sortable => "#{TimeBooking.table_name}.started_on", :caption => :field_tt_date, :groupable => "DATE(#{TimeBooking.table_name}.started_on)"))
      base.add_available_column(QueryColumn.new(:tt_log_date, :sortable => "#{TimeLog.table_name}.started_on", :caption => :field_tt_date, :groupable => "DATE(#{TimeLog.table_name}.started_on)"))
      base.add_available_column(QueryColumn.new(:get_formatted_start_time, :caption => :field_tt_start))
      base.add_available_column(QueryColumn.new(:get_formatted_stop_time, :caption => :field_tt_stop))
      base.add_available_column(QueryColumn.new(:get_formatted_time, :caption => :field_tt_time))
      base.add_available_column(QueryColumn.new(:get_formatted_bookable_hours, :caption => :field_tt_bookable))
      base.add_available_column(QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :caption => :field_tt_issue, :groupable => "#{Issue.table_name}.subject"))
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    def tt_query?
      self.tt_query
    end

    def tt_query=(flag)
      if !self.tt_query? && flag
        self.filters.delete('status_id') if self.filters
      elsif self.tt_query? && !flag
        self.filters ||= {'status_id' => {:operator => "o", :values => [""]}} # reset original values
      end

      write_attribute(:tt_query, flag)
      # to force a recalculation, we have to set columns and filters "nil"
      @available_columns = nil
      @available_filters = nil
    end

    def initialize_with_time_tracker(attributes=nil, *args)
      initialize_without_time_tracker attributes
      self.filters.delete('status_id') if tt_query?
    end

    # standard is unable to order groups! but we want to, so we do not define a default ;)
    def group_by_sort_order_with_time_tracker
      unless tt_query?
        group_by_sort_order_without_time_tracker
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
      unless tt_query?
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

      # use raw Query as template to get the content for two complex fields without copying the source
      tq = Query.new

      # unless-statements are used as workaround to get the code working for the migration file "011_add_default_tt_query"
      @available_filters['tt_project'] = tq.available_filters_without_time_tracker["project_id"].clone unless tq.available_filters_without_time_tracker["project_id"].nil?
      @available_filters['tt_start_date'] = {:type => :date, :order => 2}
      @available_filters['tt_issue'] = {:type => :list, :order => 4, :values => Issue.all.collect { |s| [s.subject, s.id.to_s] }}
      @available_filters['tt_user'] = tq.available_filters_without_time_tracker["author_id"].clone unless tq.available_filters_without_time_tracker["author_id"].nil?

      @available_filters.each do |field, options|
        options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
      end

      @available_filters
    end

    # Returns the bookings count
    def booking_count
      # TODO refactor includes
      TimeBooking.
          includes([:project, :virtual_comment, {:time_entry => :issue}, {:time_log => :user}]).
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
          r = TimeBooking.
              includes([:project, :virtual_comment, {:time_entry => :issue}, {:time_log => :user}]).
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

      TimeBooking.
          includes([:project, :virtual_comment, {:time_entry => :issue}, {:time_log => :user}]).
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
      TimeLog.bookable.
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
          r = TimeLog.bookable.
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

      TimeLog.bookable.
          #includes([:project, :issue, :user]).
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
    def sql_for_tt_project_field(field, operator, value)
      if value.delete('mine')
        value += User.current.memberships.map(&:project_id).map(&:to_s)
      end
      if operator == "="
        "( #{TimeBooking.table_name}.project_id IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
      else
        "( #{TimeBooking.table_name}.project_id NOT IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") OR #{TimeBooking.table_name}.project_id IS NULL )"
      end
    end

    def sql_for_tt_start_date_field(field, operator, value)
      case operator
        when "="
          "DATE(#{TimeBooking.table_name}.started_on) = '#{Time.parse(value[0]).to_date}'"
        when ">="
          "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.parse(value[0]).to_date}'"
        when "<="
          "DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.parse(value[0]).to_date}'"
        when "><"
          "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.parse(value[0]).to_date}' AND DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.parse(value[1]).to_date}'"
        when "<t+"
          "DATE(#{TimeBooking.table_name}.started_on) > '#{value[0].to_i.days.to_date}'"
        when ">t+"
          "DATE(#{TimeBooking.table_name}.started_on) < '#{value[0].to_i.days.to_date}'"
        when "t+"
          "DATE(#{TimeBooking.table_name}.started_on) = '#{value[0].to_i.days.to_date}'"
        when "t"
          "DATE(#{TimeBooking.table_name}.started_on) = '#{Time.now.localtime.to_date}'"
        when "w"
          "DATE(#{TimeBooking.table_name}.started_on) >= '#{Time.now.localtime.beginning_of_week.to_date}' AND DATE(#{TimeBooking.table_name}.started_on) <= '#{Time.now.localtime.end_of_week.to_date}'"
        when ">t-"
          "DATE(#{TimeBooking.table_name}.started_on) > '#{value[0].to_i.days.ago.to_date}'"
        when "<t-"
          "DATE(#{TimeBooking.table_name}.started_on) < '#{value[0].to_i.days.ago.to_date}'"
        when "t-"
          "DATE(#{TimeBooking.table_name}.started_on) = '#{value[0].to_i.days.ago.to_date}'"
        when "!*"
          "DATE(#{TimeBooking.table_name}.started_on) IS NULL"
        when "*"
          "DATE(#{TimeBooking.table_name}.started_on) IS NOT NULL"
        else
          "#{TimeBooking.table_name}.started_on >= '#{(Time.now.localtime-2.weeks).beginning_of_day.to_date}'"
      end
    end

    def sql_for_tt_issue_field(field, operator, value)
      "( #{Issue.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
    end

    def sql_for_tt_user_field(field, operator, value)
      if value.delete('me')
        value += User.current.id.to_s.to_a
      end
      "( #{User.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
    end
  end
end

Query.send(:include, QueryPatch)