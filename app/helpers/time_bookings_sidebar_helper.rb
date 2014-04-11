module TimeBookingsSidebarHelper
  def sidebar_queries
    unless @sidebar_queries
      @sidebar_queries = TimeBookingQuery.visible.all(
          :order => "#{Query.table_name}.name ASC",
          # Project specific queries and global queries
          :conditions => (@project.nil? ? ["project_id IS NULL"] : ["project_id IS NULL OR project_id = ?", @project.id])
      )
    end
    @sidebar_queries
  end

end