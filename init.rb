# encoding: utf-8
Rails.logger.info 'Starting Time Tracker plugin for RedMine'

require 'redmine'

# patching the user-class of redmine, so we can reference the users time-log easier
require 'user_patch'
require 'project_patch'
require 'menu_patch'
require 'query_patch'

require 'sort_helper_patch'
require 'application_helper_patch'
require 'queries_controller_patch'
require 'issues_helper_patch'
require 'context_menus_controller_patch'

# workaround helping rails to find the helper-methods
require File.join(File.dirname(__FILE__), "app", "helpers", "application_helper.rb")

# TODO rails 3.2 has assets-directories as sub-dirs in app, lib and vendor => maybe we should organize our assets that way!

require_dependency 'time_tracker_hooks'

Redmine::Plugin.register :redmine_time_tracker do
  name 'Redmine Time Tracker plugin'
  author 'Christian Reich'
  description 'This is a plugin to track time in Redmine'
  version '0.4.1'

  requires_redmine :version_or_higher => '2.0.0'

  settings :default => {:refresh_rate => '60', :status_transitions => {}}, :partial => 'settings/time_tracker'

  # following permission-setting will be found in a plugin-specific field within the roles-settings
  project_module :redmine_timetracker_plugin_settings do
    permission :use_time_tracker_plugin, {:time_trackers => [:start, :stop, :delete],
                                          :time_logs => [:add_booking, :show_booking, :get_list_entry],
                                          :time_list => :index,
                                          :tt_overview => :index,
                                          :tt_info => :index,
                                          :time_bookings => [:delete]},
               :require => :loggedin
  end
  # following permission will be set-up within the "project"-field in the roles-settings
  permission :delete_others_time_trackers, :time_trackers => :delete

  permission :view_others_time_trackers, :tt_info => :index

  # setup an menu entry into the redmine top-menu on the upper left corner
  menu :top_menu, :time_tracker_main_menu, {:controller => 'tt_overview', :action => 'index'}, :caption => :time_tracker_label_main_menu,
       :if => Proc.new { User.current.logged? }

  Redmine::MenuManager.map :timetracker_menu do |menu|
    menu.push :time_tracker_menu_tab_overview, {:controller => 'tt_overview', :action => 'index'}, :caption => :time_tracker_label_menu_tab_overview, :if => Proc.new { User.current.logged? }
    menu.push :time_tracker_menu_tab_list, {:controller => 'time_list', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs, :if => Proc.new { User.current.logged? }
    #menu.push :time_tracker_menu_tab_stats, {:controller => 'time_logs', :action => 'index'}, :caption => :time_tracker_label_menu_tab_stats, :if => Proc.new { User.current.logged? }
    menu.push :time_tracker_menu_tab_active_trackers, {:controller => 'tt_info', :action => 'index'}, :caption => :time_tracker_label_menu_tab_active_trackers, :if => Proc.new { User.current.logged? }
  end
end

# Helper access from the model
class TTHelper
  # TODO check for Singleton. seems not be used if included like this:
  # code is original from redmine_time_tracker-plugin
  include Singleton
  include TimeTrackersHelper
end

# to call helper methods from the model use help.<helper_method>
# in the controllers, the TimeTrackerHelper was included separately, so all methods can be called without any prefix
# that is necessary to make variables like params[] available to the helper-methods
def help
  TTHelper.instance
end

