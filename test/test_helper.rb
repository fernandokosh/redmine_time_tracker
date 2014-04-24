# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
ActiveSupport::TestCase.fixture_path=File.dirname(__FILE__) + '/fixtures/'

# next two lines are necessary to get Unit-Tests handled by RubyMine
require "minitest/reporters"
MiniTest::Reporters.use!

Zonebie.set_random_timezone

def local_time(date)
  User.current.time_zone.parse(date).localtime.strftime("%H:%M")
end

def local_date(date)
  User.current.time_zone.parse(date).localtime.to_date.to_s(:db)
end