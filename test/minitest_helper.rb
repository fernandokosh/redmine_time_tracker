# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + '/fixtures/'

if (Gem::Version.new(ENV['REDMINE_VERSION']) < Gem::Version.new('2.6.4')) && !ENV['REDMINE_VERSION'].nil?
  # make output prettier
  Turn.config.format = :progress
end

# setup capybara for integration tests
require 'capybara/rails'
require 'capybara/poltergeist'
require 'minitest/autorun'

if (Gem::Version.new(ENV['REDMINE_VERSION']) >= Gem::Version.new('2.6.4')) && !ENV['REDMINE_VERSION'].nil?
  require 'minitest/reporters'
  Minitest::Reporters.use!
end

module RedmineTimeTracker 
  class IntegrationTest < ActionDispatch::IntegrationTest
    include Rails.application.routes.url_helpers
    include Capybara::DSL
    self.use_transactional_fixtures = false
    self.fixture_path = File.dirname(__FILE__) + '/fixtures/'

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {debug: false, :default_wait_time => 30, :timeout => 90, inspector: true, :js_errors => false})
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.default_driver = :poltergeist

    def log_user(login, password)
      visit '/my/page'
      assert_equal '/login', current_path
      within('#login-form form') do
        
        fill_in 'username', :with => login
        fill_in 'password', :with => password
        page.save_screenshot("#{screenshot_path}/before.png")

        find('input[name=login]').click
        User.current = User.find_by_login(login)
      end
      assert_equal '/my/page', current_path
    end

    def screenshot_path
      Rails.root.join('tmp/screenshots')
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
