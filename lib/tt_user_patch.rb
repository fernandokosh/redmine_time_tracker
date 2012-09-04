require_dependency 'project'
require_dependency 'principal'

module UserPatch
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :time_logs
      has_many :time_bookings, :through => :time_logs
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

User.send(:include, UserPatch)