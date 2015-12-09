require File.dirname(__FILE__) + '../../minitest_helper'

class OverviewIntegrationTest < RedmineTimeTracker::IntegrationTest
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses,
           :enabled_modules, :enumerations, :time_entries, :time_logs, :time_bookings

  def setup
    log_user('admin', 'admin')
    Setting.default_language = 'en'
    Timecop.travel(Time.local(2012, 10, 30, 12, 0, 0))
  end

  def has_empty_table(type, page)
    assert_match(I18n::t("time_tracker_label_your_#{type.to_s}"), page.text)
    page.assert_no_selector(:css, "div#user-#{type.to_s}-list")
  end

  context 'User with full permissions' do
    context 'and no TimeLogs' do
      setup do
        TimeLog.where(user_id: 1).each {|d| d.delete}
      end

      should 'not have any elements in the logs table' do
        visit '/tt_overview'
        has_empty_table(:time_logs, page)
      end

      should 'not have any elements in the logs table from other users' do
        visit '/tt_overview'
        has_empty_table(:time_logs, page)
      end
    end

    context 'with TimeLogs' do
      setup do
        TimeLog.find(1).delete
        TimeLog.find(2).delete
      end

      should 'see the all logs from the last 2 weeks' do
        visit '/tt_overview'
        assert_match('actual time log', page.text)
      end

      should 'not see logs older than 2 weeks' do
        visit '/tt_overview'
        assert_no_match(/old time log/, page.text)
      end
    end

    context 'and no Bookings' do
      setup do
        TimeBooking.find(2).delete
        TimeBooking.find(3).delete
        TimeBooking.find(4).delete
      end

      should 'not have any elements in the bookings table' do
        visit '/tt_overview'
        has_empty_table(:time_bookings, page)
      end

      should 'not have any elements in the bookings table from other users' do
        visit '/tt_overview'
        has_empty_table(:time_bookings, page)
      end
    end

    context 'and Bookings' do
      setup do
        TimeBooking.find(1).delete
        TimeBooking.find(2).delete
      end

      should 'see all the bookings from the last 2 weeks' do
        visit '/tt_overview'
        page.assert_selector(:css, 'td.tt_booking_date', :text => '10/29/2012')
      end

      should 'not see bookings older than 2 weeks' do
        visit '/tt_overview'
        page.assert_no_selector(:css, 'td.tt_booking_date', :text => '10/29/2011')
      end
    end
  end
end
