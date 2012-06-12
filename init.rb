# encoding: utf-8
Rails.logger.info 'Starting Time Tracker plugin for RedMine'

require 'redmine'

# patching the user-class of redmine, so we can reference the users time-log easier
require 'user_patch'
User.send(:include, UserPatch)

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
    permission :view_time_trackers, {:time_trackers => [:index, :start, :stop, :delete]}, :require => :loggedin
  end
  # following permission will be set-up within the "project"-field in the roles-settings
  #permission :delete_others_time_trackers, :time_trackers => :delete

  # setup an menu entry into the redmine top-menu on the upper left corner
  menu :top_menu, :time_tracker_main_menu, {:controller => 'time_trackers', :action => 'index'}, :caption => :time_tracker_label_main_menu, :if => Proc.new { User.current.logged? }

  menu :application_menu, :time_tracker_menu_tab_overview, { :controller => 'time_trackers', :action => 'index'},
       {
           :caption => :time_tracker_label_menu_tab_overview,
           # TODO figure out a condition that enables the menu only for the timeTracker-page
           :if => Proc.new { User.current.logged? }
       }
  Redmine::MenuManager.map :application_menu do |menu|
    menu.push :time_tracker_menu_tab_logs, { :controller => 'time_logs', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs, :if => Proc.new { User.current.logged? }
  end
end
