require File.dirname(__FILE__) + '../../minitest_helper'


class TimeLogsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations, :time_entries, :time_logs

  def setup
    Timecop.travel(Time.local(2012, 10, 30, 12, 0, 0))
    @controller = TimeLogsController.new
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
  context "time_logs" do
    setup do
      Role.find(2).remove_permission! :tt_log_time
      Role.find(2).remove_permission! :tt_edit_own_time_logs
      Role.find(2).remove_permission! :tt_edit_time_logs
      Role.find(2).remove_permission! :tt_view_bookings
      Role.find(2).remove_permission! :tt_book_time
      Role.find(2).remove_permission! :tt_edit_own_bookings
      Role.find(2).remove_permission! :tt_edit_bookings
      @request.session[:user_id] = 2 # user2 is developer
      @request.env["HTTP_REFERER"] = '/tt_overview' # set this to get "redirect_to :back" working properly
    end

    context "without any permission" do
      should "deny access" do
        # actions leads to add_booking and/or update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_booking
        assert_response 403, "on show_booking"
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

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TL"
        get :show_booking
        assert_response 403, "on show_booking"
      end

      should "update only TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "not update time or date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:47:00"), tl.started_on, "not updated TL-date")
      end

      should "not update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("original comment", tl.comments, "not updated foreign TL-comment")
      end

      should "not update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:47:00"), tl.started_on, "not updated TL-date")
      end
    end

    context "with :tt_edit_own_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_time_logs
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        get :delete
        assert_response 302, "on delete TL"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :show_booking
        assert_response 403, "on show_booking"
      end

      should "update TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "also update time and date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-23 12:42:00"), tl.started_on, "not updated TL-date")
      end

      should "not update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("original comment", tl.comments, "not updated foreign TL-comment")
      end

      should "not update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:47:00"), tl.started_on, "not updated TL-date")
      end
    end

    context "with :tt_edit_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_time_logs
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        get :delete
        assert_response 302, "on delete TL"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :show_booking
        assert_response 403, "on show_booking"
      end

      should "update TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "also update time and date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-23 12:42:00"), tl.started_on, "not updated TL-date")
      end

      should "update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("new comment", tl.comments, "updated foreign TL-comment")
      end

      should "update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-23 12:42:00"), tl.started_on, "not updated TL-date")
      end
    end

    context "with :tt_view_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_view_bookings
      end

      should "deny access" do
        # actions leads to add_booking and/or update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_booking
        assert_response 403, "on show_booking"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
      end
    end

    context "with :tt_book_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_book_time
      end

      should "deny access" do
        # actions leads to add_booking and/or update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
        @request.accept = "text/javascript"
        get :show_booking
        assert_response 200, "on show_booking"
      end
    end

    context "with :tt_book_time and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_book_time
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :show_booking
        assert_response 200, "on show_booking"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TL"
      end

      should "update only TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "not update time or date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:47:00"), tl.started_on, "not updated TL-date")
      end

      should "not update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("original comment", tl.comments, "not updated foreign TL-comment")
      end

      should "not update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:47:00"), tl.started_on, "not updated TL-date")
      end
    end

    context "with :tt_edit_own_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_bookings
      end

      should "deny access" do
        # actions leads to add_booking and/or update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
        @request.accept = "text/javascript"
        get :show_booking
        assert_response 200, "on show_booking"
      end
    end

    context "with :tt_edit_own_bookings and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_edit_own_bookings
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :show_booking
        assert_response 200, "on show_booking"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TL"
      end

      should "update only TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "not update time or date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:47:00"), tl.started_on, "not updated TL-date")
      end

      should "not update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("original comment", tl.comments, "not updated foreign TL-comment")
      end

      should "not update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:47:00"), tl.started_on, "not updated TL-date")
      end
    end

    context "with :tt_edit_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_bookings
      end

      should "deny access" do
        # actions leads to add_booking and/or update..
        get :actions
        assert_response 403, "on start TL"
        get :delete
        assert_response 403, "on delete TL"
        get :show_edit
        assert_response 403, "on show_edit"
        get :get_list_entry
        assert_response 403, "on get_list_entry"
        @request.accept = "text/javascript"
        get :show_booking
        assert_response 200, "on show_booking"
      end
    end

    context "with :tt_edit_bookings and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_edit_bookings
      end

      should "allow access" do
        get :actions
        assert_response 302, "on TL actions"
        @request.accept = "text/javascript"
        get :show_edit, {:time_log_ids => [1]}
        assert_response 200, "on show_edit"
        get :show_booking
        assert_response 200, "on show_booking"
        get :get_list_entry, {:time_log_id => 1}
        assert_response 200, "on get_list_entry"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TL"
      end

      should "update only TL -comments on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "23:47", :stop_time => "23:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        tl = TimeLog.where(:id => 1).first
        assert_equal("new comment", tl.comments, "updated TL-comment")
      end

      should "not update time or date on own logs" do
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-25 23:47:00"), tl.started_on, "not updated TL-datetime")
      end

      should "update TL -comments on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-25",
                                                :start_time => "08:47", :stop_time => "08:53",
                                                :spent_time => "6m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal("new comment", tl.comments, "not updated foreign TL-comment")
      end

      should "not update time or date on foreign logs" do
        get :actions, {:time_log_edit => {2 => {:id => 2, :comments => "new comment", :tt_log_date => "2012-10-23",
                                                :start_time => "12:42", :stop_time => "12:52",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_foreign_logs), flash[:error], "show error-message")
        tl = TimeLog.where(:id => 2).first
        assert_equal(local_datetime("2012-10-25 8:47:00"), tl.started_on, "not updated TL-datetime")
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

      should "update date and time on logs when passing params in different time and date format" do
        Setting.date_format = '%d.%m.%Y'
        get :actions, {:time_log_edit => {1 => {:id => 1, :comments => "new comment", :tt_log_date => "23.10.2012",
                                                :start_time => "9:48 pm", :stop_time => "9:52 pm",
                                                :spent_time => "10m"}}}
        assert_response 302, "on update TL"
        assert_equal(I18n.t(:tt_update_log_success), flash[:notice] || flash[:error], "show flash-message")
        tl = TimeLog.where(:id => 1).first
        assert_equal(local_datetime("2012-10-23 21:48:00"), tl.started_on, "not updated TL-datetime")
      end
    end
  end
end