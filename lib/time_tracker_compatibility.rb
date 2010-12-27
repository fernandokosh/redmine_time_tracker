# Wrappers around the Redmine Core API changes between versions
module TimeTrackerCompatibility
  class TimelogController
    # Wrapper around Redmine's API since TimelogController changed in trunk @ r4239
    # This can be removed once 1.1.0 is stable
    def self.correct_logtime_action?
      ::TimelogController.method_defined?("new") ? 'new' : 'edit'
    end
  end
end
