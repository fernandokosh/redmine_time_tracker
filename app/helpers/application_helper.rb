module ApplicationHelper
    def time_tracker_for(user)
        TimeTracker.find(:first, :conditions => { :user_id => user.id })
    end

    def status_from_id(status_id)
        IssueStatus.find(:first, :conditions => { :id => status_id })
    end

    def statuses_list()
        IssueStatus.find(:all)
    end

    def to_status_options(statuses)
        options_from_collection_for_select(statuses, 'id', 'name')
    end

    def new_transition_from_options(transitions)
        statuses = []
        for status in statuses_list()
            if !transitions.has_key?(status.id.to_s)
                statuses << status
            end
        end
        to_status_options(statuses)
    end

    def new_transition_to_options()
        to_status_options(statuses_list())
    end

    def global_allowed_to?(user, action)
        return false if user.nil?

        projects = Project.find(:all)
        for p in projects
            if user.allowed_to?(action, p)
                return true
            end
        end

        return false
    end
    
    def render_project_select_box
      
      projects = User.current.projects.all
      disabled = @time_tracker.nil? ? '' : ' disabled'
      
      if projects.any?
        s = '<select id="project_select"' + disabled + '>' +
              "<option value=''>#{ l(:label_jump_to_a_project) }</option>" +
              '<option value="" disabled="disabled">---</option>'
        s << project_tree_options_for_select(projects, :selected => @project) do |p|
          { :value => p.identifier }
        end
        s << '</select>'
        s
      end

    end    
end