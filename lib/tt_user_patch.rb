require_dependency 'project'
require_dependency 'principal'

module UserPatch
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :time_logs
      has_many :time_bookings, :through => :time_logs

      alias_method_chain :remove_references_before_destroy, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def remove_references_before_destroy_with_time_tracker
      remove_references_before_destroy_without_time_tracker

      substitute = User.anonymous
      TimeLog.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
    end
  end
end

User.send(:include, UserPatch)