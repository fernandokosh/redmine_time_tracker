class TtCompleterController < ApplicationController
  before_filter :authorize_global

  def get_issue
    compl = TtCompleter.new(:query => params[:query])
    compl.get_issue
    respond_to do |format|
      format.json { render :json => compl }
    end
  end
end
