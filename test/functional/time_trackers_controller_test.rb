require File.dirname(__FILE__) + '../../test_helper'

class TimeTrackersControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations, :time_entries, :time_trackers

  def setup
    @controller = TimeTrackersController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end

  # test_permissions
  context "time_trackers" do
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
        get :start
        assert_response 403, "on start TT"
        get :update
        assert_response 403, "on update TT"
        get :stop
        assert_response 403, "on stop TT"
        get :delete
        assert_response 403, "on delete TT"
      end
    end

    context "with :tt_log_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_log_time
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        assert_redirected_to :controller => 'tt_overview'
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
        assert_redirected_to :controller => 'tt_overview'
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        # stopping the tracker from the fixtures should fail, cause there is set an issue-id which will end in an
        # booking => at this point the user has no right to create TimeBookings => stop must fail!
        assert_difference 'TimeTracker.count', 0 do
          get :stop
        end

        # now we create a new TimeTracker without "illegal" information to test proper stopping!
        TimeTracker.delete_all
        get :start
        assert_equal(1, TimeTracker.count, "TimeTracker.count should be 1")
        tt = TimeTracker.first
        assert_equal(2, tt.user_id, "user_id = 2")
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      should "update only TT -comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update only TT -round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "not update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal(1, tt.issue_id, "illegally updated TT-issue_id")
      end

      should "not update project_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal(1, tt.issue_id, "illegally nullified issue_id")
        assert_equal(1, tt.project_id, "illegally updated TT-project_id")
      end

      should "not update time or date on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "illegally updated TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "illegally updated TT-date")
      end
    end

    context "with :tt_edit_own_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_time_logs
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
        get :delete
        assert_response 302, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        assert_difference 'TimeTracker.count', 0 do
          get :stop
        end

        TimeTracker.delete_all
        get :start
        assert_equal(1, TimeTracker.count, "TimeTracker.count is 1")
        tt = TimeTracker.first
        assert_equal(2, tt.user_id, "user_id = 2")
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      #=============================
      # should "update own TimeTrackers completely"
      should "update comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(2, tt.issue_id, "updated TT-issue_id")
      end

      should "update project_id and issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(nil, tt.issue_id, "nullified issue_id")
        assert_equal(nil, tt.project_id, "updated TT-project_id")
      end

      should "update date and time on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("10:23:42", tt.started_on.localtime.to_time.strftime("%H:%M:%S"), "updated TT-start_time")
        assert_equal("2012-10-23", tt.started_on.to_date.to_s(:db), "updated TT-date")
      end
      #=============================

      #=============================
      # should "deny updating foreign TimeTrackers completely"
      should "not update comments on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("original comment", tt.comments, "not updated foreign TT-comment")
      end

      should "not update round on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(false, tt.round, "not updated foreign TT-round")
      end

      should "not update issue_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not updated foreign TT-issue_id")
      end

      should "not update issue_id or project_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not nullified foreign issue_id")
        assert_equal(1, tt.project_id, "not updated foreign TT-project_id")
      end

      should "not update date or time on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated foreign TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated foreign TT-date")
      end
      #=============================
    end

    context "with :tt_edit_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_time_logs
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
        get :delete
        assert_response 302, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        assert_difference 'TimeTracker.count', 0 do
          get :stop
        end

        TimeTracker.delete_all
        get :start
        assert_equal(1, TimeTracker.count, "TimeTracker.count is 1")
        tt = TimeTracker.first
        assert_equal(2, tt.user_id, "user_id = 2")
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      #=============================
      # should "update own TimeTrackers completely"
      should "update comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(2, tt.issue_id, "updated TT-issue_id")
      end

      should "update project_id and issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(nil, tt.issue_id, "nullified issue_id")
        assert_equal(nil, tt.project_id, "updated TT-project_id")
      end

      should "update date and time on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("10:23:42", tt.started_on.localtime.to_time.strftime("%H:%M:%S"), "updated TT-start_time")
        assert_equal("2012-10-23", tt.started_on.to_date.to_s(:db), "updated TT-date")
      end
      #=============================

      #=============================
      # should "deny updating foreign TimeTrackers completely"
      should "not update comments on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("original comment", tt.comments, "not updated foreign TT-comment")
      end

      should "not update round on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(false, tt.round, "not updated foreign TT-round")
      end

      should "not update issue_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not updated foreign TT-issue_id")
      end

      should "not update issue_id or project_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not nullified foreign issue_id")
        assert_equal(1, tt.project_id, "not updated foreign TT-project_id")
      end

      should "not update date or time on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated foreign TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated foreign TT-date")
      end
      #=============================
    end

    context "with :tt_view_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_view_bookings
      end

      should "deny access" do
        get :start
        assert_response 403, "on start TT"
        get :update
        assert_response 403, "on update TT"
        get :stop
        assert_response 403, "on stop TT"
        get :delete
        assert_response 403, "on delete TT"
      end
    end

    context "with :tt_book_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_book_time
      end

      should "deny access" do
        get :start
        assert_response 403, "on start TT"
        get :update
        assert_response 403, "on update TT"
        get :stop
        assert_response 403, "on stop TT"
        get :delete
        assert_response 403, "on delete TT"
      end
    end

    context "with :tt_book_time and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_book_time
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      # ============================
      #should "update everything but time and date on own TimeTrackers"
      should "update comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(2, tt.issue_id, "updated TT-issue_id")
      end

      should "update issue_id and project_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal(nil, tt.issue_id, "nullified issue_id")
        assert_equal(nil, tt.project_id, "updated TT-project_id")
      end

      should "not update date or time on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated TT-start_time illegally")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated TT-date illegally")
      end
      # ============================

      #=============================
      # should "deny updating foreign TimeTrackers completely"
      should "not update comments on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("original comment", tt.comments, "not updated foreign TT-comment")
      end

      should "not update round on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(false, tt.round, "not updated foreign TT-round")
      end

      should "not update issue_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not updated foreign TT-issue_id")
      end

      should "not update issue_id or project_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not nullified foreign issue_id")
        assert_equal(1, tt.project_id, "not updated foreign TT-project_id")
      end

      should "not update date or time on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated foreign TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated foreign TT-date")
      end
      #=============================
    end

    context "with :tt_edit_own_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_bookings
      end

      should "deny access" do
        get :start
        assert_response 403, "on start TT"
        get :update
        assert_response 403, "on update TT"
        get :stop
        assert_response 403, "on stop TT"
        get :delete
        assert_response 403, "on delete TT"
      end
    end

    context "with :tt_edit_own_bookings and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_edit_own_bookings
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      # ============================
      #should "update everything but time and date on own TimeTrackers"
      should "update comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(2, tt.issue_id, "updated TT-issue_id")
      end

      should "update issue_id and project_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal(nil, tt.issue_id, "nullified issue_id")
        assert_equal(nil, tt.project_id, "updated TT-project_id")
      end

      should "not update date or time on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated TT-start_time illegally")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated TT-date illegally")
      end
      # ============================

      #=============================
      # should "deny updating foreign TimeTrackers completely"
      should "not update comments on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("original comment", tt.comments, "not updated foreign TT-comment")
      end

      should "not update round on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(false, tt.round, "not updated foreign TT-round")
      end

      should "not update issue_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not updated foreign TT-issue_id")
      end

      should "not update issue_id or project_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not nullified foreign issue_id")
        assert_equal(1, tt.project_id, "not updated foreign TT-project_id")
      end

      should "not update date or time on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated foreign TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated foreign TT-date")
      end
      #=============================
    end

    context "with :tt_edit_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_bookings
      end

      should "deny access" do
        get :start
        assert_response 403, "on start TT"
        get :update
        assert_response 403, "on update TT"
        get :stop
        assert_response 403, "on stop TT"
        get :delete
        assert_response 403, "on delete TT"
      end
    end

    context "with :tt_edit_bookings and :tt_log_time permission" do
      setup do
        Role.find(2).add_permission! :tt_log_time
        Role.find(2).add_permission! :tt_edit_bookings
      end

      should "allow access" do
        get :start
        assert_response 302, "on start TT"
        get :update
        assert_response 200, "on update TT"
        get :stop
        assert_response 302, "on stop TT"
      end

      should "deny access" do
        get :delete
        assert_response 403, "on delete TT"
      end

      should "start a TT correctly" do
        TimeTracker.delete_all
        assert_difference('TimeTracker.count') do
          get :start
        end
      end

      should "stop a TT correctly" do
        assert_difference 'TimeTracker.count', -1 do
          get :stop
        end
      end

      # ============================
      #should "update everything but time and date on own TimeTrackers"
      should "update comments on own trackers" do
        put :update, {:time_tracker => {:comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal("new comment", tt.comments, "updated TT-comment")
      end

      should "update round on own trackers" do
        put :update, {:time_tracker => {:round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(true, tt.round, "updated TT-round")
      end

      should "update issue_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 1).first
        assert_equal(2, tt.issue_id, "updated TT-issue_id")
      end

      should "update issue_id and project_id on own trackers" do
        put :update, {:time_tracker => {:issue_id => nil, :project_id => nil}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal(nil, tt.issue_id, "nullified issue_id")
        assert_equal(nil, tt.project_id, "updated TT-project_id")
      end

      should "not update date or time on own trackers" do
        put :update, {:time_tracker => {:start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        #assert_equal(I18n.t(:tt_error_not_allowed_to_change_logs), flash[:error], "flashing the right error")
        tt = TimeTracker.where(:id => 1).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated TT-start_time illegally")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated TT-date illegally")
      end
      # ============================

      #=============================
      # should "deny updating foreign TimeTrackers completely"
      should "not update comments on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :comments => "new comment"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("original comment", tt.comments, "not updated foreign TT-comment")
      end

      should "not update round on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :round => true}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(false, tt.round, "not updated foreign TT-round")
      end

      should "not update issue_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => 2}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not updated foreign TT-issue_id")
      end

      should "not update issue_id or project_id on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :issue_id => nil, :project_id => nil}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal(1, tt.issue_id, "not nullified foreign issue_id")
        assert_equal(1, tt.project_id, "not updated foreign TT-project_id")
      end

      should "not update date or time on foreign trackers" do
        put :update, {:time_tracker => {:id => 2, :start_time => "10:23:42", :date => "2012-10-23"}}
        assert_response :success
        tt = TimeTracker.where(:id => 2).first
        assert_equal("11:47:03", tt.started_on.to_time.strftime("%H:%M:%S"), "not updated foreign TT-start_time")
        assert_equal("2012-10-25", tt.started_on.to_date.to_s(:db), "not updated foreign TT-date")
      end
      #=============================
    end
  end
end
