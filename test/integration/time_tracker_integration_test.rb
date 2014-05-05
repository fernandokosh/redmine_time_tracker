require File.dirname(__FILE__) + '../../minitest_helper'


class TimeTrackerIntegrationTest < RedmineTimeTracker::IntegrationTest
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations
  def setup
    log_user('jsmith', 'jsmith')
  end

  context 'User with permission :tt_log_time' do
    setup do
      Role.find(2).add_permission! :tt_log_time
      #puts "Current user: #{User.current.login} - permission granted: #{Role.find(2).permissions.include? :tt_log_time}"
    end

    should "have permission to start a time tracker" do
      visit '/tt_overview'
      page.text.must_include 'Your time logs'
      find('#start-time-tracker-button').click
      page.text.must_include 'Started the time tracker'
      find('#stop-time-tracker-button').click
    end

    should "have started one time tracker" do
      visit '/tt_overview'
      find('#start-time-tracker-button').click
      time_tracker = TimeTracker.where(user_id: User.current.id)
      assert_equal(time_tracker.exists?, true)
      find('#stop-time-tracker-button').click
    end

    should "have created a time log after stopping the time tracker" do
      visit '/tt_overview'
      find('#start-time-tracker-button').click
      find('#stop-time-tracker-button').click
      page.text.must_include 'Stopped the time tracker'
      time_logs = TimeLog.where(user_id: User.current.id)
      assert_equal(time_logs.size, 1)
    end
  end


  context 'User without permissions' do
    setup do
      
      Role.find(2).remove_permission! :tt_log_time
      #puts "Current user: #{User.current.login} - permission removed: #{!Role.find(2).permissions.include? :tt_log_time}"
    end

    should 'not have permission to start a time tracker' do
      visit '/tt_overview'
      page.text.must_include 'You are not authorized to access this page.'
    end
  end


end