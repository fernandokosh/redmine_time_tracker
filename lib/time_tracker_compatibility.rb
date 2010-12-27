# Wrappers around the Redmine Core API changes between versions
module TimeTrackerCompatibility
  class TimelogController
    # Wrapper around Redmine's API since TimelogController changed in trunk @ r4239
    # This can be removed once 1.1.0 is stable
    def self.correct_logtime_action?
      if ::TimelogController.method_defined?("new")
        return 'new'
      else
        return 'edit'
      end
    end
  end
end
