require_dependency 'application_helper'

module ApplicationHelperPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :link_to_issue, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def link_to_issue_with_time_tracker(issue, options={})
      if !@query.nil? && !@query.tt_query?
        link_to_issue_without_time_tracker(issue, options)
      else
        link_to_issue_without_time_tracker(issue)
      end
    end
  end
end

ApplicationHelper.send(:include, ApplicationHelperPatch)