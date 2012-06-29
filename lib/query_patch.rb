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
      alias_method_chain :available_filters, :pj

      base.add_available_column(QueryColumn.new(:id, :sortable => "#{TimeBooking.table_name}.id", :caption => "bookings"))
      base.add_available_column(QueryColumn.new(:time_log_id, :sortable => "#{TimeLog.table_name}.id", :caption => "logs"))
      base.add_available_column(QueryColumn.new(:time_entry_id, :sortable => "#{TimeEntry.table_name}.id", :caption => "entries"))
      base.add_available_column(QueryColumn.new(:comments, :sortable => "#{TimeEntry.table_name}.comments", :caption => "comments"))
      base.add_available_column(QueryColumn.new(:user, :sortable => "#{User.table_name}.login", :caption => "user"))
    end
  end

  module ClassMethods
  end

  # TODO refactor the instance methods!!
  module InstanceMethods

    def available_filters_with_pj
      @available_filters = available_filters_without_pj
      @available_filters['pj'] = @available_filters["project_id"]
      @available_filters
    end

    # Returns the bookings count
    def booking_count
      # TODO refactor includes
      TimeBooking.count(:include => [:time_log, :time_entry], :conditions => statement)
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

    # Returns the bookings count by group or nil if query is not grouped
    def booking_count_by_group
      r = nil
      if grouped?
        begin
          # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
          r = TimeBooking.count(:group => group_by_statement, :include => [:time_log, :time_entry], :conditions => statement)
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

      # TODO figure out what benefits are coming with the joins and how to use them correctly
      #joins = (order_option && order_option.include?('authors')) ? "LEFT OUTER JOIN users authors ON authors.id = #{Issue.table_name}.author_id" : nil
      #joins = "LEFT JOIN time_entries ON #{TimeEntry.table_name}.id = #{TimeBooking.table_name}.time_entry_id"
      joins = nil

      TimeBooking.scoped(:conditions => options[:conditions]).find :all, :include => ([:time_entry => :project, :time_log => :user] + (options[:include] || [])).uniq,
                                                                   :conditions => statement,
                                                                   :order => order_option,
                                                                   :joins => joins,
                                                                   :limit => options[:limit],
                                                                   :offset => options[:offset]

    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

    # sql statements for where clauses have to be in an "sql_for_#{filed-name}_field" method
    def sql_for_pj_field(field, operator, value)
      if value.delete('mine')
        value += User.current.memberships.map(&:project_id).map(&:to_s)
      end

      "(#{TimeBooking.table_name}.virtual = 't' AND #{TimeLog.table_name}.project_id IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )" +
          " OR ( #{TimeBooking.table_name}.virtual = 'f' AND  #{TimeEntry.table_name}.project_id IN (" + value.collect { |val| "'#{connection.quote_string(val)}'" }.join(",") + ") )"
    end
  end
end
