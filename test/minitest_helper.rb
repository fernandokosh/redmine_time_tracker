# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
ActiveSupport::TestCase.fixture_path=File.dirname(__FILE__) + '/fixtures/'

# make output prettier
Turn.config.format = :progress
Zonebie.set_random_timezone

def local_datetime(datetime)
  User.current.time_zone.parse(datetime).localtime
end 