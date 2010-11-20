require 'redmine'

require_dependency 'time_tracker_hooks'

Redmine::Plugin.register :redmine_time_tracker do
    name 'Redmine Time Tracker plugin'
    author 'Jérémie Delaitre'
    description 'This is a plugin to track time in Redmine'
    version '0.3'

    requires_redmine :version_or_higher => '0.9.0'

    settings :default => { 'refresh_rate' => '60', 'status_transitions' => {} }, :partial => 'settings/time_tracker'
    

    menu :account_menu, :time_tracker_menu, '',
        {
            :caption => '',
            :html => { :id => 'time-tracker-menu' },
            :first => true,
            :param => :project_id,
            :if => Proc.new { User.current.logged? }
        }
        
        
    menu :account_menu, :time_tracker_popup, { :controller => 'time_trackers', :action => 'popup_tracker'},
      {
        
          :caption => 'Popup',
          :html => { 
            :id => 'time-tracker-popup', 
            :target => '_blank',
            :onClick => 'openPopup();return false'
          },
          :first => false,
          :param => :project_id,
          :if => Proc.new { User.current.logged? }
        
      }

    menu :top_menu, :time_tracker_admin_menu, { :controller => 'time_trackers', :action => 'index' },
        {
            :caption => :time_tracker_admin_menu,
            :if => Proc.new { User.current.admin }
        }
        

end