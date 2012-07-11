require_dependency 'query'
require_dependency 'project'
require_dependency 'active_record'
require_dependency 'plugins/redmine_time_tracker/app/models/time_booking'
require_dependency 'plugins/redmine_time_tracker/app/models/time_log'

# TODO write a declarative comment
module QueryPatch
  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :available_filters, :time_tracker

      base.add_available_column(QueryColumn.new(:id, :sortable => "#{TimeBooking.table_name}.id", :caption => :field_tt_booking_id))
      base.add_available_column(QueryColumn.new(:time_log_id, :sortable => "#{TimeLog.table_name}.id", :caption => :field_tt_time_log_id))
      base.add_available_column(QueryColumn.new(:time_entry_id, :sortable => "#{TimeEntry.table_name}.id", :caption => :field_tt_time_entry_id))
      base.add_available_column(QueryColumn.new(:comments, :sortable => "#{TimeEntry.table_name}.comments", :caption => :field_tt_comments))
      base.add_available_column(QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => :field_tt_user))
    end
  end

  module ClassMethods
  end

  # TODO refactor the instance methods!!
  module InstanceMethods

    def available_filters_with_time_tracker

      # speedup for recursive calls, so we only calc the content for the query once!
      return @available_filters if @available_filters

      @available_filters = available_filters_without_time_tracker

      # use raw Query as template to get the content for two complex fields without copying the source
      tq = Query.new

      @available_filters['tt_project'] = tq.available_filters_without_time_tracker["project_id"].clone       # :oder => 1
      @available_filters['tt_start_date'] = { :type => :date, :order => 2 }
      @available_filters['tt_due_date'] = { :type => :date, :order => 3 }
      @available_filters['tt_issue'] = { :type => :list, :order => 4, :values => Issue.all.collect{|s| [s.subject, s.id.to_s] } }
      @available_filters['tt_user'] = tq.available_filters_without_time_tracker["author_id"].clone           # :oder => 5
      @available_filters['tt_comments'] = { :type => :text, :order => 6 }
      @available_filters
    end

    # Returns the bookings count
    def booking_count
      # TODO refactor includes
      # for some reason including the :project will result in an "ambiguous column" - error if we try to group by "project"
      #TimeBooking.count(:include => [:project, :virtual_comment, :time_entry, :time_log => :user], :conditions => statement)
      TimeBooking.count(:include => [:virtual_comment, :time_entry, :time_log => :user], :conditions => statement)
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

    # Returns the bookings count by group or nil if query is not grouped
    def booking_count_by_group
      r = nil
      if grouped?
        begin
          # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
          r = TimeBooking.count(:group => group_by_statement, :include => [:virtual_comment, :time_entry, :time_log => :user], :conditions => statement)
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

      TimeBooking.scoped(:conditions => options[:conditions]).
          includes(([:project, :virtual_comment, :time_entry, :time_log => :user] + (options[:include] || [])).uniq).
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
      # stub
    end

    def sql_for_tt_due_date_field(field, operator, value)
      # stub
    end

    def sql_for_tt_issue_field(field, operator, value)
      # stub
    end

    def sql_for_tt_user_field(field, operator, value)
      if value.delete('me')
        value += User.current.id.to_s.to_a
      end
      "( #{User.table_name}.id #{operator == "=" ? 'IN' : 'NOT IN'} (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
    end

    def sql_for_tt_comments_field(field, operator, value)
      # stub
    end
  end
end
