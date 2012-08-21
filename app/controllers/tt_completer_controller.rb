class TtCompleterController < ApplicationController
  before_filter :authorize_global

  def get_issue(flag = 0)
    compl = TtCompleter.new(:query => params[:query])
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
