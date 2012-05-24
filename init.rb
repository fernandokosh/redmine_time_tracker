# encoding: utf-8
Rails.logger.info 'Starting Time Tracker plugin for RedMine'

require 'redmine'

# workaround helping rails to find the helper-methods
require File.join(File.dirname(__FILE__), "app", "helpers", "application_helper.rb")

require_dependency 'time_tracker_hooks'

Redmine::Plugin.register :redmine_time_tracker do
  name 'Redmine Time Tracker plugin'
  author 'Jérémie Delaitre'
  description 'This is a plugin to track time in Redmine'
  version '0.4'

  requires_redmine :version_or_higher => '2.0.0'

  settings :default => {:refresh_rate => '60', :status_transitions => {}}, :partial => 'settings/time_tracker'

  ### settings die hier einfach so rein gehaun werden, sind dann im menü roles->permissions
  ### unter dem punkt "projekt" zu finden. sollen sie in den pluginspezifischen settings aufauchen,
  ### müssen sie zwischen "project_module <beschriftung_der_settings> do <...> end"

  # following permission-setting will be found in a plugin-specific field within the roles-settings
  project_module :redmine_imetracker_plugin_settings do
    permission :view_others_time_trackers, :time_trackers => :index
  end
  # following permission will be set-up within the "project"-field in the roles-settings
  permission :delete_others_time_trackers, :time_trackers => :delete

  ### einen eintrag in das menü oben links einhängen geht so:
  ### mit der option ":last => true" wird es automatisch der letzte eintrag (sofern nicht später noch einer mit der gleichen
  ### option später angehängt wurde) sonst erscheint es imer vor administration und help, weil beide das :last -flag gesetzt haben
  menu :top_menu, :neues_menu, {:controller => 'time_trackers', :action => 'index'}, :caption => 'mein Menu', :last => true

  menu :account_menu, :time_tracker_menu, '',
       {
           :caption => '',
           :html => {:id => 'time-tracker-menu'},
           :first => true,
           :param => :project_id,
           :if => Proc.new { User.current.logged? }
       }
end
