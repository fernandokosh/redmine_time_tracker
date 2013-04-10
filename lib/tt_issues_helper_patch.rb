require_dependency 'issues_helper'

module IssuesHelperPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :sidebar_queries, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def sidebar_queries_with_time_tracker
      sidebar_queries_without_time_tracker
      if %w(tt_reporting tt_bookings_list).include? controller_name
        @sidebar_queries.delete_if { |item| item.tt_query_type != 2 }
      elsif %w(tt_logs_list).include? controller_name
        @sidebar_queries.delete_if { |item| item.tt_query_type != 1 }
      else
        @sidebar_queries.delete_if { |item| item.tt_query? }
      end
    end
  end
end

IssuesHelper.send(:include, IssuesHelperPatch)