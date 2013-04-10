module IssuePatch
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :time_entries, :dependent => :destroy
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end

Issue.send(:include, IssuePatch)