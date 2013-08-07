# This class hooks into Redmine's View Listeners in order to add content to the page
class TimeTrackerHooks < Redmine::Hook::ViewListener
  render_on :view_issues_context_menu_start, :partial => 'time_trackers/update_context'
  render_on :view_issues_show_description_bottom, :partial => 'time_trackers/issue_action_menu'
  render_on :view_layouts_base_html_head, :partial => 'time_trackers/assets'

  def controller_issues_bulk_edit_before_save(context={})
    controller_issues_edit_before_save context
  end

  def controller_issues_edit_before_save(context={})
    issue = context[:issue]
    if issue.closed?
      TimeTracker.where(:issue_id => issue.id).all.each do |timer|
        if timer.activity_id.nil?
          timer.activity_id = TimeEntryActivity.find_or_create_by_name(:name => :ticket_closed, :active => false).id
        end
        timer.stop
      end
    end
  end
end
