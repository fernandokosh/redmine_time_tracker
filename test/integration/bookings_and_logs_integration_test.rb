require File.dirname(__FILE__) + '../../minitest_helper'

class BookingsAndLogsIntegrationTest < RedmineTimeTracker::IntegrationTest
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :issues, :issue_statuses,
           :enabled_modules, :enumerations

  def setup
    log_user('admin', 'admin')
    Setting.default_language = 'en'
    Timecop.travel(Time.local(2012, 10, 30, 12, 0, 0))
  end

  def cleanup
    TimeLog.delete_all
    TimeBooking.delete_all
    TimeTracker.delete_all
  end

  def generate_booking
    cleanup
    visit '/tt_logs_list'
    find(:css, 'a.tt_start').click
    find(:css, 'a.tt_stop').click

    visit '/tt_logs_list'
    find(:css, 'a.icon-time', :visible => false).trigger('click')
    find(:css, "#time_log_add_booking_#{TimeLog.first.id}_project_id_select option[value='1']").select_option
    find(:css, "#time_log_add_booking_#{TimeLog.first.id}_activity_id_select option[value='10']").select_option
    find(:css, '.tl_book_form_button').click
  end

  context 'User with full permissions' do
    context 'using the global timer' do
      should 'not have bookings before starting the timer' do
        cleanup
        visit '/tt_bookings_list'
        assert_match(I18n::t('label_no_data'), page.text)
      end

      should 'not have bookings after stopping the timer' do
        cleanup
        visit '/tt_bookings_list'
        find(:css, 'a.tt_start').click
        find(:css, 'a.tt_stop').click

        visit '/tt_bookings_list'
        assert_match(I18n::t('label_no_data'), page.text)
      end

      should 'not have logs before starting the timer' do
        cleanup
        visit '/tt_logs_list'
        assert_match(I18n::t('label_no_data'), page.text)
      end

      should 'have a log after stopping the timer' do
        cleanup
        visit '/tt_logs_list'
        find(:css, 'a.tt_start').click
        find(:css, 'a.tt_stop').click

        visit '/tt_logs_list'
        assert_no_match(/#{I18n::t('label_no_data')}/, page.text)
        page.assert_selector(:css, 'table.tt_list')
      end

      should 'have a booking entry after booking a logged time', :js => true, :type => :feature do
        generate_booking
        visit '/tt_bookings_list'
        assert_match('eCookbook', page.text)
        assert_no_match(/#{I18n::t('label_no_data')}/, page.text)
      end

      should 'have a booking entry after booking a logged time at the report tab', :js => true, :type => :feature do
        generate_booking
        visit '/tt_reporting'
        assert_match('eCookbook', page.text)
        assert_no_match(/#{I18n::t('label_no_data')}/, page.text)
      end
    end
  end
end
