module TimeEntryPatch
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_one :time_booking, :dependent => :destroy
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

TimeEntry.send(:include, TimeEntryPatch)