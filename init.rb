require 'redmine'

require_dependency 'time_tracker_hooks'

Redmine::Plugin.register :chiliproject_time_tracker do
    name 'ChiliProject Time Tracker plugin'
    author 'Jérémie Delaitre, magic labs*'
    description 'This is a plugin to track time in ChiliProject'
    version '0.4'

    requires_redmine :version_or_higher => '1.1.0'

    settings :default => { 'refresh_rate' => '60', 'status_transitions' => {} }, :partial => 'settings/time_tracker'

    permission :view_others_time_trackers, :time_trackers => :index
    permission :delete_others_time_trackers, :time_trackers => :delete

end
