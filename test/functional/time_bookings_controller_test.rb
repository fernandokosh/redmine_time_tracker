require File.dirname(__FILE__) + '../../test_helper'

class TimeBookingsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations, :time_entries, :time_bookings

  def setup
    @controller = TimeBookingsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
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
        flunk "not implemented yet!"
      end
    end

    context "with :tt_log_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_log_time
      end
    end

    context "with :tt_edit_own_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_time_logs
      end
    end

    context "with :tt_edit_time_logs permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_time_logs
      end
    end

    context "with :tt_view_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_view_bookings
      end
    end

    context "with :tt_book_time permission only" do
      setup do
        Role.find(2).add_permission! :tt_book_time
      end
    end

    context "with :tt_edit_own_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_own_bookings
      end
    end

    context "with :tt_edit_bookings permission only" do
      setup do
        Role.find(2).add_permission! :tt_edit_bookings
      end
    end
  end
end