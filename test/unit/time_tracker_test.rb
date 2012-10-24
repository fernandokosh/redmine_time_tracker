require File.dirname(__FILE__) + '../../test_helper'
ActiveSupport::TestCase.fixture_path=File.dirname(__FILE__) + '/../fixtures/'

class TimeTrackerTest < ActiveSupport::TestCase
  fixtures :time_trackers

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
