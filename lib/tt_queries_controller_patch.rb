require_dependency 'queries_controller'

module QueriesControllerPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :new, :time_tracker
      alias_method_chain :create, :time_tracker
      alias_method_chain :update, :time_tracker
      alias_method_chain :destroy, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def new_with_time_tracker
      new_without_time_tracker
      q_type = params[:tt_query_type].to_i
      if q_type > 0
        @query.tt_query_type = q_type
        build_query_from_params
      end
    end

    def create_with_time_tracker
      @query = Query.new(params[:query])
      @query.tt_query_type = params[:tt_query_type].to_i
      @query.user = User.current
      @query.project = params[:query_is_for_all] ? nil : @project
      @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      build_query_from_params
      @query.column_names = nil if params[:default_columns]

      if @query.save
        flash[:notice] = l(:notice_successful_create)
        if @query.tt_query?
          redirect_to params[:tt_request_referer], :project_id => @project, :query_id => @query
        else
          redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
        end
      else
        render :action => 'new', :layout => !request.xhr?
      end
    end

    def update_with_time_tracker
      @query.attributes = params[:query]
      @query.tt_query_type = params[:tt_query_type].to_i
      @query.project = nil if params[:query_is_for_all]
      @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      build_query_from_params
      @query.column_names = nil if params[:default_columns]

      if @query.save
        flash[:notice] = l(:notice_successful_update)
        if @query.tt_query?
          redirect_to params[:tt_request_referer], :project_id => @project, :query_id => @query
        else
          redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
        end
      else
        render :action => 'edit'
      end
    end

    def destroy_with_time_tracker
      if @query.tt_query?
        @query.destroy
        redirect_to URI(request.referer).path, :set_filter => 1
      else
        destroy_without_time_tracker
      end
    end
  end
end

QueriesController.send(:include, QueriesControllerPatch)