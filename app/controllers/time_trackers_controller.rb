class TimeTrackersController < ApplicationController
    unloadable

    def index
        if User.current.nil?
            @user_time_trackers = nil
            @time_trackers = TimeTracker.find(:all)
        else
            @user_time_trackers = TimeTracker.find(:all, :conditions => { :user_id => User.current.id })
            @time_trackers = TimeTracker.find(:all, :conditions => [ 'user_id != ?', User.current.id ])
        end
    end

    def start
        @time_tracker = current
        if @time_tracker.nil?
            @issue = Issue.find(:first, :conditions => { :id => params[:issue_id] })
            @time_tracker = TimeTracker.new({ :issue_id => @issue.id })

            if @time_tracker.save
                apply_status_transition(@issue) unless Setting.plugin_redmine_time_tracker['status_transitions'] == nil
                render_menu
            else
                flash[:error] = l(:start_time_tracker_error)
            end
        else
            flash[:error] = l(:time_tracker_already_running_error)
        end
    end

    def resume
        @time_tracker = current
        if @time_tracker.nil? or not @time_tracker.paused
            flash[:error] = l(:no_time_tracker_suspended)
            redirect_to :back
        else
            @time_tracker.started_on = Time.now
            @time_tracker.paused = false
            if @time_tracker.save
                render_menu
            else
                flash[:error] = l(:resume_time_tracker_error)
            end
        end
    end

    def suspend
        @time_tracker = current
        if @time_tracker.nil? or @time_tracker.paused
            flash[:error] = l(:no_time_tracker_running)
            redirect_to :back
        else
            @time_tracker.time_spent = @time_tracker.hours_spent
            @time_tracker.paused = true
            if @time_tracker.save
                render_menu
            else
                flash[:error] = l(:suspend_time_tracker_error)
            end
        end
    end

    def stop
        @time_tracker = current
        if @time_tracker.nil?
            flash[:error] = l(:no_time_tracker_running)
            redirect_to :back
        else
            issue_id = @time_tracker.issue_id
            hours = @time_tracker.hours_spent.round(2)
            @time_tracker.destroy

            redirect_to :controller => 'issues', :action => 'edit', :id => issue_id, :time_entry => { :hours => hours }
        end
    end

    def delete
        time_tracker = TimeTracker.find(:first, :conditions => { :id => params[:id] })
        if !time_tracker.nil?
            time_tracker.destroy
            render :text => l(:time_tracker_delete_success)
        else
            render :text => l(:time_tracker_delete_fail)
        end
    end

    def render_menu
        @project = Project.find(:first, :conditions => { :id => params[:project_id] })
        @issue = Issue.find(:first, :conditions => { :id => params[:issue_id] })
        render :partial => 'embed_menu'
    end

    def add_status_transition
        transitions = params[:transitions].nil? ? {} : params[:transitions]
        transitions[params[:from_id]] = params[:to_id]

        render :partial => 'status_transition_list', :locals => { :transitions => transitions }
    end

    def delete_status_transition
        transitions = params[:transitions].nil? ? {} : params[:transitions]
        transitions.delete(params[:from_id])

        render :partial => 'status_transition_list', :locals => { :transitions => transitions }
    end

    protected

    def current
        TimeTracker.find(:first, :conditions => { :user_id => User.current.id })
    end

    def apply_status_transition(issue)
        new_status_id = Setting.plugin_redmine_time_tracker['status_transitions'][issue.status_id.to_s]
        new_status = IssueStatus.find(:first, :conditions => { :id => new_status_id })
        if issue.new_statuses_allowed_to(User.current).include?(new_status)
            journal = @issue.init_journal(User.current, notes = l(:time_tracker_label_transition_journal))
            @issue.status_id = new_status_id
            @issue.save
        end
    end
end
