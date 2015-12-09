require File.dirname(__FILE__) + '../../minitest_helper'


class TimeBookingsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations, :time_entries, :time_bookings, :time_logs

  def setup
    Timecop.travel(Time.local(2012, 10, 30, 12, 0, 0))
    @controller = TimeBookingsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
    Setting.date_format = '%Y-%m-%d'

    # Quick fix for Redmine > 3.0 so the tests do not need to send an XHR request when the response will be
    # JavaScript
    subject.class.skip_before_filter :verify_authenticity_token
  end

  # test_permissions
  context "time_bookings" do
    setup do
      Role.find(2).remove_permission! :tt_log_time
      Role.find(2).remove_permission! :tt_edit_own_time_logs
      Role.find(2).remove_permission! :tt_edit_time_logs
      Role.find(2).remove_permission! :tt_view_bookings
      Role.find(2).remove_permission! :tt_book_time
      Role.find(2).remove_permission! :tt_edit_own_bookings
      Role.find(2).remove_permission! :tt_edit_bookings
      @request.session[:user_id] = 2 # user2 is developer => no permission => should not reach any action
      @request.env["HTTP_REFERER"] = '/tt_overview' # set this to get "redirect_to :back" working properly
    end

    context "without any permission" do
      should "deny access" do
        # actions leads to update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
      end
    end

    context "with :tt_log_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_log_time
      end

      should "deny access" do
        # actions leads to update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
      end
    end

    context "with :tt_edit_own_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_time_logs
      end

      should "deny access" do
        # actions leads to update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
      end
    end

    context "with :tt_edit_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_time_logs
      end

      should "deny access" do
        # actions leads to update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
      end
    end

    context "with :tt_view_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_view_bookings
      end

      should "deny access" do
        # actions leads to update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
      end

      should "allow access" do
        @request.accept = "text/javascript"
        get :get_list_entry, {:time_booking_id => 1}
        assert_response 200, "on get_list_entry"
      end
    end

    context "with :tt_book_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_book_time
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        @request.accept = "text/javascript"
        get :show_edit, {:time_booking_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_booking_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TL"
      end

      should "update TB -comments/issue/activity and project on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:47", :stop_time => "23:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_nil(flash[:error], "no error messages")
        tb = TimeBooking.where(:id => 1).first
        assert_equal("new comment", tb.comments, "updated TB-comment")
        assert_equal(2, tb.issue.id, "updated TB-issue")
        assert_equal(10, tb.activity_id, "updated TB-activity")
      end

      should "not update time or date on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:48", :stop_time => "23:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_booking), flash[:error], "show error-message")
        tb = TimeBooking.where(:id => 1).first

        assert_equal(local_datetime('2012-10-25 23:47:00'), tb.started_on, "not updated TB datetime")
      end

      should "not update TB -comments/issue/activity or project on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:47", :stop_time => "08:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_booking), flash[:error], "show error-message")
        tb = TimeBooking.where(:id => 2).first
        assert_equal("original comment", tb.comments, "updated TB-comment")
        assert_equal(1, tb.issue.id, "updated TB-issue")
        assert_equal(9, tb.activity_id, "updated TB-activity")
      end

      should "not update time or date on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:48", :stop_time => "08:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_booking), flash[:error], "show error-message")
        tb = TimeBooking.where(:id => 2).first
        
        assert_equal(local_datetime("2012-10-25 08:47:00"), tb.started_on, "not updated TB-datetime")
      end
    end

    context "with :tt_edit_own_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_bookings
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        get :delete
        assert_response 302, "on delete TL"
        @request.accept = "text/javascript"
        get :show_edit, {:time_booking_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_booking_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "update TB -comments/issue/activity and project on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:47", :stop_time => "23:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_nil(flash[:error], "no error messages")
        tb = TimeBooking.where(:id => 1).first
        assert_equal("new comment", tb.comments, "updated TB-comment")
        assert_equal(2, tb.issue.id, "updated TB-issue")
        assert_equal(10, tb.activity_id, "updated TB-activity")
      end

      should "update time and date on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:48", :stop_time => "23:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_update_booking_success), flash[:notice] || flash[:error], "show flash-message")
        tb = TimeBooking.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:48:00"), tb.started_on, "not updated TB-datetime")
      end

      should "not update TB -comments/issue/activity or project on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:47", :stop_time => "08:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_booking), flash[:error], "show error-message")
        tb = TimeBooking.where(:id => 2).first
        assert_equal("original comment", tb.comments, "updated TB-comment")
        assert_equal(1, tb.issue.id, "updated TB-issue")
        assert_equal(9, tb.activity_id, "updated TB-activity")
      end

      should "not update time or date on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:48", :stop_time => "08:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_booking), flash[:error], "show error-message")
        tb = TimeBooking.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 08:47:00"), tb.started_on, "not updated TB-datetime")
      end
    end

    context "with :tt_edit_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_bookings
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        get :delete
        assert_response 302, "on delete TL"
        @request.accept = "text/javascript"
        get :show_edit, {:time_booking_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_booking_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "update TB -comments/issue/activity and project on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:47", :stop_time => "23:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_nil(flash[:error], "no error messages")
        tb = TimeBooking.where(:id => 1).first
        assert_equal("new comment", tb.comments, "updated TB-comment")
        assert_equal(2, tb.issue.id, "updated TB-issue")
        assert_equal(10, tb.activity_id, "updated TB-activity")
      end

      should "update time and date on own bookings" do
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "23:48", :stop_time => "23:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_update_booking_success), flash[:notice] || flash[:error], "show flash-message")
        tb = TimeBooking.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:48:00"), tb.started_on, "not updated TB-datetime")
      end

      should "update TB -comments/issue/activity and project on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "new comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:47", :stop_time => "08:53",
                                                    :spent_time => "6m", :project_id => 1, :issue_id => 2, :activity_id => 10}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_update_booking_success), flash[:notice] || flash[:error], "show flash-message")
        tb = TimeBooking.where(:id => 2).first
        assert_equal("new comment", tb.comments, "updated TB-comment")
        assert_equal(2, tb.issue.id, "updated TB-issue")
        assert_equal(10, tb.activity_id, "updated TB-activity")
      end

      should "update time and date on foreign bookings" do
        get :actions, {:time_booking_edit => {2 => {:id => 2, :comments => "original comment", :tt_booking_date => "2012-10-25",
                                                    :start_time => "08:48", :stop_time => "08:51",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_update_booking_success), flash[:notice] || flash[:error], "show flash-message")
        tb = TimeBooking.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:48:00"), tb.started_on, "not updated TB-date")
      end
    end

    context "with all permissions and foreign user" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_edit_own_time_logs
        Role.find(2).add_permission! :tt_edit_time_logs
        Role.find(2).add_permission! :tt_view_bookings
        Role.find(2).add_permission! :tt_book_time
        Role.find(2).add_permission! :tt_edit_own_bookings
        Role.find(2).add_permission! :tt_edit_bookings
        @request.session[:user_id] = 1 #user 1 has the timezone UTC
      end

      should "update date and time on bookings when passing params in different time and date format" do
        Setting.date_format = '%d.%m.%Y'
        get :actions, {:time_booking_edit => {1 => {:id => 1, :comments => "original comment", :tt_booking_date => "25.10.2012",
                                                    :start_time => "9:48 pm", :stop_time => "9:51 pm",
                                                    :spent_time => "3m", :project_id => 1, :issue_id => 1, :activity_id => 9}}}
        assert_response 302, "on update TB"
        assert_equal(I18n.t(:tt_update_booking_success), flash[:notice] || flash[:error], "show flash-message")
        tb = TimeBooking.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 21:48:00"), tb.started_on, "not updated TB-date")
      end
    end
  end
end