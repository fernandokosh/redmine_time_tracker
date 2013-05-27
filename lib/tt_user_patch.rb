require_dependency 'user'
require_dependency 'project'
require_dependency 'principal'

# patching the user-class of redmine, so we can reference the users time-log easier
module TtUserPatch
  extend ActiveSupport::Concern

  included do
    class_eval do
      has_many :time_logs
      has_many :time_bookings, :through => :time_logs
    end
  end

  def remove_references_before_destroy
    super
    substitute = ::User.anonymous
    TimeLog.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
  end
end

User.send :include, TtUserPatch
