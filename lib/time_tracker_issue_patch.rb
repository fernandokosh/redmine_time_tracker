module TimeTrackerIssuePatch
    def self.included(base) #:nodoc:
        base.send :include, InstanceMethods
        base.class_eval do
            after_update :update_time_trackers
        end
    end

    module InstanceMethods
        def update_time_trackers
            return true unless default_activity = TimeEntryActivity.default
            return true unless self.status_id_changed?
            transitions = Setting.plugin_redmine_time_tracker.fetch :stop_status_transitions, {}
            from, to = self.status_id_change
            return true unless transitions[from.to_s].to_i == to
            TimeTracker.find(:all, :conditions => { :issue_id => self.id }).each do |tt|
                time_entry_attrs = {
                    :project  => self.project,
                    :activity => default_activity,
                    :user     => tt.user,
                    :spent_on => Date.today,
                    :hours    => tt.hours_spent.round(2)
                }
                tt.destroy if self.time_entries.create time_entry_attrs
            end
        end
        private :update_time_trackers
    end
end
