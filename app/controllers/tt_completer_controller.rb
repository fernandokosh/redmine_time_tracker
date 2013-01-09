class TtCompleterController < ApplicationController
  before_filter :authorize_global
  accept_api_auth :get_issue, :get_issue_id, :get_issue_subject

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
end
