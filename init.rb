# encoding: utf-8
Rails.logger.info 'Starting Time Tracker plugin for RedMine'

require 'redmine'

# patching the user-class of redmine, so we can reference the users time-log easier
require 'tt_user_patch'
require 'tt_project_patch'
require 'tt_menu_patch'
require 'tt_query_patch'
require 'tt_issue_patch'
require 'tt_time_entry_patch'

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
  version '0.5'

  requires_redmine :version_or_higher => '2.1.0'

  #settings :default => {:refresh_rate => '60', :status_transitions => {}}, :partial => 'settings/time_tracker'
  settings :default => {:report_title => 'Report', :report_logo_url => '', :report_logo_width => '150'}, :partial => 'settings/time_tracker'

  Redmine::AccessControl.map do |map|
    map.project_module :redmine_timetracker_plugin do
      # start/stop trackers, view own timeLogs, partially edit own timeLogs (issue, comments)
      map.permission :tt_log_time, {:time_logs => [:actions, :get_list_entry, :show_edit],
                                    :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                    :tt_info => [:index],
                                    :tt_overview => [:index],
                                    :time_trackers => [:start, :stop, :update]},
                     :require => :loggedin
      # all from :tt_log_time + completely edit own timeLogs
      map.permission :tt_edit_own_time_logs, {:time_logs => [:actions, :delete, :get_list_entry, :show_edit],
                                              :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                              :tt_logs_list => [:index],
                                              :tt_info => [:index],
                                              :tt_overview => [:index],
                                              :time_trackers => [:delete, :start, :stop, :update]},
                     :require => :loggedin
      # all from :tt_edit_own_time_logs + completely edit foreign timeLogs
      map.permission :tt_edit_time_logs, {:time_logs => [:actions, :delete, :get_list_entry, :show_edit],
                                          :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                          :tt_date_shifter => [:get_next_time_span, :get_prev_time_span],
                                          :tt_logs_list => [:index],
                                          :tt_info => [:index],
                                          :tt_overview => [:index],
                                          :time_trackers => [:delete, :start, :stop, :update]},
                     :require => :loggedin
      # view only reports-page (view all foreign timeBookings)
      map.permission :tt_view_bookings, {:time_bookings => [:get_list_entry],
                                         :tt_date_shifter => [:get_next_time_span, :get_prev_time_span],
                                         :tt_reporting => [:index, :print_report]},
                     :require => :loggedin
      # book time, view own timeBookings, partially edit own timeBookings (issue, comments, project)
      map.permission :tt_book_time, {:time_bookings => [:actions, :get_list_entry, :show_edit, :update],
                                     :time_logs => [:show_booking],
                                     :tt_bookings_list => [:index],
                                     :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                     :tt_date_shifter => [:get_next_time_span, :get_prev_time_span],
                                     :tt_info => [:index],
                                     :tt_overview => [:index],
                                     :tt_reporting => [:index, :print_report]},
                     :require => :loggedin
      # all from :tt_book_time + completely edit own timBookings
      map.permission :tt_edit_own_bookings, {:time_bookings => [:actions, :delete, :get_list_entry, :show_edit, :update],
                                             :time_logs => [:show_booking],
                                             :tt_bookings_list => [:index],
                                             :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                             :tt_date_shifter => [:get_next_time_span, :get_prev_time_span],
                                             :tt_info => [:index],
                                             :tt_overview => [:index],
                                             :tt_reporting => [:index, :print_report]},
                     :require => :loggedin
      # all from :tt_edit_own_bookings + completely edit foreign timeBookings
      map.permission :tt_edit_bookings, {:time_bookings => [:actions, :delete, :get_list_entry, :show_edit, :update],
                                         :time_logs => [:show_booking],
                                         :tt_bookings_list => [:index],
                                         :tt_completer => [:get_issue, :get_issue_id, :get_issue_subject],
                                         :tt_date_shifter => [:get_next_time_span, :get_prev_time_span],
                                         :tt_info => [:index],
                                         :tt_overview => [:index],
                                         :tt_reporting => [:index, :print_report]},
                     :require => :loggedin
    end
  end

  def permission_checker(permission_list)
    proc {
      flag = false
      permission_list.each { |permission|
        flag ||= User.current.allowed_to_globally?(permission, {})
      }
      flag
    }
  end

  # setup an menu entry into the redmine top-menu on the upper left corner
  menu :top_menu, :time_tracker_main_menu, {:controller => 'tt_menu_switcher', :action => 'index'}, :caption => :time_tracker_label_main_menu,
       # if the user has one or more of the permissions declared within this Plug-In, he should see the "TimeTracker"-Menu
       :if => permission_checker([:tt_log_time, :tt_edit_own_time_logs, :tt_edit_time_logs, :tt_view_bookings, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings])

  Redmine::MenuManager.map :timetracker_menu do |menu|
    menu.push :time_tracker_menu_tab_overview, {:controller => 'tt_overview', :action => 'index'}, :caption => :time_tracker_label_menu_tab_overview,
              :if => permission_checker([:tt_log_time, :tt_edit_own_time_logs, :tt_edit_time_logs, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings])
    menu.push :time_tracker_menu_tab_bookings_list, {:controller => 'tt_bookings_list', :action => 'index'}, :caption => :time_tracker_label_menu_tab_bookings_list,
              :if => permission_checker([:tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings])
    menu.push :time_tracker_menu_tab_logs_list, {:controller => 'tt_logs_list', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs_list,
              :if => permission_checker([:tt_edit_own_time_logs, :tt_edit_time_logs])
    menu.push :time_tracker_menu_tab_active_trackers, {:controller => 'tt_info', :action => 'index'}, :caption => :time_tracker_label_menu_tab_active_trackers,
              :if => permission_checker([:tt_log_time, :tt_edit_own_time_logs, :tt_edit_time_logs, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings])
    menu.push :time_tracker_menu_tab_reporting, {:controller => 'tt_reporting', :action => 'index'}, :caption => :time_tracker_label_menu_tab_reports,
              :if => permission_checker([:tt_view_bookings, :tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings])
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

