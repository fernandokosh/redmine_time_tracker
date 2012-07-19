module TimeTrackersHelper
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end

  def user_from_id(user_id)
    User.where(:id => user_id).first
  end

  def tt_retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:tt_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif params[:set_filter] || session[:tt_query].nil? || session[:tt_query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = Query.new(:tt_query => true, :name => "_")
      @query.project = @project
      build_query_from_params
      session[:tt_query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = Query.find_by_id(session[:tt_query][:id]) if session[:tt_query][:id]
      @query.tt_query = true if @query
      @query ||= Query.new(:tt_query => true, :name => "_", :filters => session[:tt_query][:filters], :group_by => session[:tt_query][:group_by], :column_names => session[:tt_query][:column_names])
      @query.project = @project
    end
  end
end
