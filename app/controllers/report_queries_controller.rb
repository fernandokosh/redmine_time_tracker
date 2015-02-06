class ReportQueriesController < ApplicationController

  before_filter :find_query, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create]

  accept_api_auth :index

  helper :queries
  include QueriesHelper

  def index
  end

  def new
    @query = ReportQuery.new
    @query.user = User.current
    @query.project = @project
    @query.build_from_params(params)
  end

  def create
    @query = ReportQuery.new(params[:query])
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to last_path(:query_id => @query)
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params[:query]
    @query.project = nil if params[:query_is_for_all]
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to last_path(:query_id => @query)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to last_path(:set_filter => 1)
  end

  private

  def find_query
    @query = ReportQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def last_path(options = {})
    target = params[:tt_request_referer] || URI(request.referer).path
    target + (target.include?('?') ? '&' : '?') + options.to_param
  end

end