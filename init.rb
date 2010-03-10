require 'redmine'

require_dependency 'time_tracker_hooks'

Redmine::Plugin.register :redmine_time_tracker do
    name 'Redmine Time Tracker plugin'
    author 'Jérémie Delaitre'
    description 'This is a plugin to track time in Redmine'
    version '0.2.0'

    requires_redmine :version_or_higher => '0.9.0'

    menu :account_menu, :time_tracker_menu, '',
        {
            :caption => '',
            :html => { :id => 'time-tracker-menu' },
            :first => true,
            :param => :project_id
        }
end

