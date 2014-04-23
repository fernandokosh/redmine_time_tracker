# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
ActiveSupport::TestCase.fixture_path=File.dirname(__FILE__) + '/fixtures/'

# next two lines are necessary to get Unit-Tests handled by RubyMine
require "minitest/reporters"
MiniTest::Reporters.use!