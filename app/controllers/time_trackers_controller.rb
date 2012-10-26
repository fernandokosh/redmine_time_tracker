class TimeTrackersController < ApplicationController
  unloadable

  menu_item :time_tracker_menu_tab_overview
  before_filter :js_auth, :authorize_global

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
      # parse comments for issue-id
      if args[:issue_id].nil? && !args[:comments].nil? && args[:comments].strip.match(/\A#\d?\d*/)
        cut = args[:comments].strip.partition(/#\d?\d*/)
        issue_id = cut[1].sub(/#/, "").to_i
        unless help.issue_from_id(issue_id).nil?
          args[:issue_id] = issue_id
          args[:comments] = cut[2].strip
        end
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
    redirect_to :controller => 'tt_overview'
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
      redirect_to :controller => 'tt_overview'
    end
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to :back
  end

  def delete
    time_tracker = TimeTracker.where(:id => params[:id]).first
    if User.current.id == time_tracker.user_id && User.current.allowed_to?([:tt_edit_own_time_logs], {}) || User.current.allowed_to_globally?([:tt_edit_time_logs], {}) # user could only delete his own entries, except he's admin
      time_tracker.destroy
    else
      flash[:error] = l(:time_tracker_delete_fail)
    end
    flash[:notice] = l(:time_tracker_delete_success)
    redirect_to :back
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to :back
  end

  def update
    @time_tracker = get_current
    @time_tracker.update_attributes!(params[:time_tracker])
    respond_to do |format|
      format.html { render :nothing => true }
      format.xml { render :xml => @time_tracker }
      format.json { render :json => @time_tracker }
    end
      # if something went wrong, return the original object
  rescue StandardError => e
    @time_tracker = get_current
    # todo figure out a way to show errors, even on ajax requests!
    flash[:error] = e.message
    respond_to do |format|
      format.html { render :nothing => true }
      format.xml { render :xml => @time_tracker }
      format.json { render :json => @time_tracker }
    end
  end

  protected

  def get_current
    current = TimeTracker.where(:user_id => User.current.id).first
    current.nil? ? TimeTracker.new : current
  end

  private

  # following method is necessary to got ajax requests logged_in
  def js_auth
    respond_to do |format|
      format.json { User.current = User.where(:id => session[:user_id]).first }
      format.any {}
    end
  end
end
