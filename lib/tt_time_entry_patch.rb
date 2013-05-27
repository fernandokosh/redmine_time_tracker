require_dependency 'time_entry'

module TtTimeEntryPatch
  extend ActiveSupport::Concern

  included do
    class_eval do
      has_one :time_booking, :dependent => :destroy
    end
  end
end

TimeEntry.send :include, TtTimeEntryPatch
