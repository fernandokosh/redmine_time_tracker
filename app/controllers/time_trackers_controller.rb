class TimeTrackersController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_overview
  before_filter :authorize_global

  # we could start an empty timeTracker to track time without any association.
  # we also can give some more information, so the timeTracker could be automatically associated later.
  def start(args = {})
    default_args= {:issue_id => nil, :comments => nil}
    args = default_args.merge(args)

    @time_tracker = get_current
    if @time_tracker.new_record?
      # TODO work out a nicer way to get the params from the form
      unless params[:time_tracker].nil?
        args[:issue_id]=params[:time_tracker][:issue_id] if args[:issue_id].nil?
        args[:comments]=params[:time_tracker][:comments] if args[:comments].nil?
      end
      @time_tracker = TimeTracker.new(:issue_id => args[:issue_id], :comments => args[:comments])
      if @time_tracker.start
        apply_status_transition(Issue.where(:id => args[:issue_id]).first) unless Setting.plugin_redmine_time_tracker[:status_transitions] == nil
      else
        flash[:error] = l(:start_time_tracker_error)
      end
    else
      flash[:error] = l(:time_tracker_already_running_error)
    end
    redirect_to "/tt_overview"
  end

  def stop
    @time_tracker = get_current
    if @time_tracker.nil?
      flash[:error] = l(:no_time_tracker_running)
      redirect_to :back
    else
      unless params[:time_tracker].nil?
        @time_tracker.issue_id = params[:time_tracker][:issue_id]
        @time_tracker.comments = params[:time_tracker][:comments]
      end
      @time_tracker.stop
      flash[:error] = l(:stop_time_tracker_error) unless @time_tracker.destroyed?
      @time_tracker = get_current
      redirect_to "/tt_overview"
    end
  end

  def delete
    time_tracker = TimeTracker.where(:id => params[:id]).first
    if time_tracker.nil?
      render :text => l(:time_tracker_delete_fail)
    else
      time_tracker.destroy
      render :text => l(:time_tracker_delete_success)
    end
  end

  def update
    @time_tracker = get_current
    @time_tracker.update_attributes(params[:time_tracker])
    respond_to do |format|
      format.html { render :nothing => true }
      format.xml { render :xml => @time_tracker }
      format.json { render :json => @time_tracker }
    end
  # if something went wrong, return the original object
  rescue
    @time_tracker = get_current
    respond_to do |format|
      format.html { render :nothing => true }
      format.xml { render :xml => @time_tracker }
      format.json { render :json => @time_tracker }
    end

  end

  def add_status_transition
    transitions = params[:transitions].nil? ? {} : params[:transitions]
    transitions[params[:from_id]] = params[:to_id]

    render :partial => 'status_transition_list', :locals => {:transitions => transitions}
  end

  def delete_status_transition
    transitions = params[:transitions].nil? ? {} : params[:transitions]
    transitions.delete(params[:from_id])

    render :partial => 'status_transition_list', :locals => {:transitions => transitions}
  end

  protected

  def get_current
    current = TimeTracker.where(:user_id => User.current.id).first
    current.nil? ? TimeTracker.new : current
  end

  def paginate_array(array, page)
    limit = 15 # 15 items per page
    page = 1 if page == 0
    limit * (page - 1) > array.size - 1 ? offset = 0 : offset = limit * (page - 1)
    offset + limit >= array.size ? stop_loop = array.size-1 : stop_loop = offset + limit - 1
               # filling the array for the view
    erg = []
    for i in offset..stop_loop
      erg.push(array[i])
    end
    {:limit => limit, :page => page, :arr => erg}
  end

  def apply_status_transition(issue)
    unless issue == nil
      new_status_id = Setting.plugin_redmine_time_tracker[:status_transitions][issue.status_id.to_s]
      new_status = IssueStatus.where(:id => new_status_id).first
      if issue.new_statuses_allowed_to(User.current).include?(new_status)
        journal = @issue.init_journal(User.current, notes = l(:time_tracker_label_transition_journal))
        @issue.status_id = new_status_id
        @issue.save
      end
    end
  end
end
