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

  settings :default => { :refresh_rate => '60', :status_transitions => {} }, :partial => 'settings/time_tracker'

  permission :view_others_time_trackers, :time_trackers => :index
  permission :delete_others_time_trackers, :time_trackers => :delete

  menu :account_menu, :time_tracker_menu, '',
       {
           :caption => '',
           :html => { :id => 'time-tracker-menu' },
           :first => true,
           :param => :project_id,
           :if => Proc.new { User.current.logged? }
       }
end
