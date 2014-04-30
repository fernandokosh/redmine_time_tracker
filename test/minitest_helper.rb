# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
ActiveSupport::TestCase.fixture_path=File.dirname(__FILE__) + '/fixtures/'

# make output prettier
Turn.config.format = :progress

# setup capybara for integration tests
require 'capybara/rails'

module RedmineTimeTracker 
  class IntegrationTest < ActionDispatch::IntegrationTest
    include Rails.application.routes.url_helpers
    include Capybara::DSL
    self.use_transactional_fixtures = false
    Capybara.default_wait_time = 15

    def log_user(login, password)
      visit '/my/page'
      assert_equal '/login', current_path
      within('#login-form form') do
        fill_in 'username', :with => login
        fill_in 'password', :with => password
        find('input[name=login]').click
      end
      assert_equal '/my/page', current_path
    end

    teardown do
      Capybara.reset_sessions!    # Forget the (simulated) browser state
      Capybara.use_default_driver # Revert Capybara.current_driver to Capybara.default_driver
    end
  end
end

Zonebie.set_random_timezone

# helper methods
def local_datetime(datetime)
  User.current.time_zone.parse(datetime).localtime
end 
