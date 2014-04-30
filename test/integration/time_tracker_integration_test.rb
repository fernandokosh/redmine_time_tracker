require File.dirname(__FILE__) + '../../minitest_helper'


class TimeTrackerIntegrationTest < RedmineTimeTracker::IntegrationTest

  context 'User' do

    def setup
      log_user('jsmith', 'jsmith') 
      # current user is John Smith (no admin) in each test of this context
      # set permissions for this user
      Role.find(2).add_permission! :tt_log_time
    end


    should "have permission to start a time tracker", js: true do
      visit '/tt_overview'
      page.text.must_include 'Your time logs'
      click_button('start')
      page.text.must_include 'Started the time tracker'
    end
  end
end