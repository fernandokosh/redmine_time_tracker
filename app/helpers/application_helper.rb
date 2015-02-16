module ApplicationHelper
  def time_tracker_for(user)
    TimeTracker.where(:user_id => user.id).first
  end

  def status_from_id(status_id)
    IssueStatus.where(:id => status_id).first
  end

  def statuses_list()
    IssueStatus.all
  end

  def to_status_options(statuses)
    options_from_collection_for_select(statuses, 'id', 'name')
  end

  def new_transition_from_options(transitions)
    statuses = []
    statuses_list().each { |status|
      statuses << status unless transitions.has_key?(status.id.to_s)
    }
    to_status_options(statuses)
  end

  def new_transition_to_options()
    to_status_options(statuses_list())
  end

  def global_allowed_to?(user, action)
    return false if user.nil?

    projects = Project.all
    projects.each { |p|
      if user.allowed_to?(action, p)
        return true
      end
    }

    false
  end

  def projects_for_time_tracking_and_current_user
    User.current.memberships.collect(&:project).compact.uniq.select { |project|
      project.allows_to? :tt_log_time
    }
  end

  # Redmine uses localized datepickers, but overrides the dateFormat setting.
  # So we need to patch it, to have it localized again.
  # We dont use a redmine patch to keep the patch limited to all timetracker forms.
  def patch_date_picker
    javascript_tag "var locDatepickerOptions = $.extend([], datepickerOptions, {dateFormat: '#{(Setting.date_format.presence || l('date.formats.default')).gsub('%m','mm').gsub('%d','dd').gsub('%Y','yy').gsub('%B','MM').gsub('%b','M')}'})"
  end
end
