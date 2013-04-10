module ProjectPatch
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :time_bookings, :dependent => :delete_all
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

Project.send(:include, ProjectPatch)