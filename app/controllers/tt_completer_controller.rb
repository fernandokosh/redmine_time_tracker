class TtCompleterController < ApplicationController
  before_filter :js_auth, :authorize_global
  accept_api_auth :get_issue, :get_issue_id, :get_issue_subject, :get_activity

  include TimeTrackersHelper

  def get_issue(flag = 0)
    compl = TtCompleter.new(:term => params[:term])
    compl.get_issue flag
    respond_to do |format|
      format.json { render :json => compl }
    end
  end

  def get_activity
    activities = get_activities(params['project_id']).map do |activity|
      {:id => activity.id, :name => activity.name}
    end
    respond_to do |format|
      format.json { render :json => activities }
    end

  end

  def get_issue_id
    get_issue 1
  end

  def get_issue_subject
    get_issue 2
  end

  private

  # following method is necessary to got ajax requests logged_in if REST-API is disabled
  def js_auth
    respond_to do |format|
      format.json { User.current = User.where(:id => session[:user_id]).first }
      format.any {}
    end
  end
end
