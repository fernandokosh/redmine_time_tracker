# encoding: utf-8
Rails.logger.info 'Starting Time Tracker plugin for RedMine'

require 'redmine'

# patching the user-class of redmine, so we can reference the users time-log easier
require 'tt_user_patch'
require 'tt_project_patch'
require 'tt_menu_patch'
require 'tt_query_patch'

require 'tt_sort_helper_patch'
require 'tt_application_helper_patch'
require 'tt_queries_controller_patch'
require 'tt_issues_helper_patch'
require 'tt_context_menus_controller_patch'

# workaround helping rails to find the helper-methods
require File.join(File.dirname(__FILE__), "app", "helpers", "application_helper.rb")

# TODO rails 3.2 has assets-directories as sub-dirs in app, lib and vendor => maybe we should organize our assets that way!

require_dependency 'tt_time_tracker_hooks'

Redmine::Plugin.register :redmine_time_tracker do
  name 'Redmine Time Tracker plugin'
  author 'Christian Reich'
  author_url 'mailto:christian.reich@hicknhack-software.com'
  description 'This is a plugin to track time in Redmine'
  version '0.4.1'

  requires_redmine :version_or_higher => '2.0.0'

  #settings :default => {:refresh_rate => '60', :status_transitions => {}}, :partial => 'settings/time_tracker'
  settings :default => {:report_title => 'Report'}, :partial => 'settings/time_tracker'

  Redmine::AccessControl.map do |map|
    map.project_module :redmine_timetracker_plugin_settings do
      map.permission :use_time_tracker_plugin, {:time_trackers => [:start, :stop, :update, :delete],
                                                :time_logs => [:actions, :update, :delete, :add_booking, :show_booking, :show_edit, :get_list_entry],
                                                :time_bookings => [:actions, :show_edit, :update, :delete, :get_list_entry],
                                                :time_list => [:index],
                                                :tt_overview => [:index],
                                                :tt_info => [:index],
                                                :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject]},
                     :require => :loggedin

      map.permission :delete_others_time_trackers, :time_trackers => :delete
      map.permission :view_others_time_trackers, :tt_info => :index
    end
  end

  # setup an menu entry into the redmine top-menu on the upper left corner
  menu :top_menu, :time_tracker_main_menu, {:controller => 'tt_overview', :action => 'index'}, :caption => :time_tracker_label_main_menu,
       :if => Proc.new { User.current.logged? }

  Redmine::MenuManager.map :timetracker_menu do |menu|
    menu.push :time_tracker_menu_tab_overview, {:controller => 'tt_overview', :action => 'index'}, :caption => :time_tracker_label_menu_tab_overview, :if => Proc.new { User.current.logged? }
    menu.push :time_tracker_menu_tab_list, {:controller => 'time_list', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs, :if => Proc.new { User.current.logged? }
    menu.push :time_tracker_menu_tab_active_trackers, {:controller => 'tt_info', :action => 'index'}, :caption => :time_tracker_label_menu_tab_active_trackers, :if => Proc.new { User.current.logged? }
    menu.push :time_tracker_menu_tab_reporting, {:controller => 'tt_reporting', :action => 'index'}, :caption => :time_tracker_label_menu_tab_reports, :if => Proc.new { User.current.logged? }
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

