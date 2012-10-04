class TtCompleterController < ApplicationController
  before_filter :js_auth, :authorize_global

  def get_issue(flag = 0)
    compl = TtCompleter.new(:term => params[:term])
    compl.get_issue flag
    respond_to do |format|
      format.json { render :json => compl }
    end
  end

  def get_issue_id
    get_issue 1
  end

  def get_issue_subject
    get_issue 2
  end

  private

  # following method is necessary to got ajax requests logged_in
  def js_auth
    respond_to do |format|
      format.json { User.current = User.where(:id => session[:user_id]).first }
      format.any {}
    end
  end
end
