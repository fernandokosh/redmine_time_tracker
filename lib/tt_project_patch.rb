require_dependency 'project'

module TtProjectPatch
  extend ActiveSupport::Concern

  included do
    class_eval do
      has_many :time_bookings, :dependent => :delete_all
    end
  end
end

Project.send :include, TtProjectPatch
