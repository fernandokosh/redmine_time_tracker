require File.dirname(__FILE__) + '../../minitest_helper'


class TimeTrackerIntegrationTest < RedmineTimeTracker::IntegrationTest

  context 'Time tracker integration' do

    def setup
      log_user('jsmith', 'jsmith') 
      # current user is John Smith (no admin) in each test of this context
      # set permissions for this user
    end


    should "have permission to visit time tracker overview page" do
      Role.find(2).add_permission! :tt_log_time
      visit '/tt_overview'

      page.text.must_include 'Your time logs'
    end
  end
end

