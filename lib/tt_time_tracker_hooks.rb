# This class hooks into Redmine's View Listeners in order to add content to the page
class TimeTrackerHooks < Redmine::Hook::ViewListener
  render_on :view_issues_context_menu_start, :partial => 'time_trackers/update_context'
  render_on :view_issues_show_description_bottom, :partial => 'time_trackers/issue_action_menu'
  render_on :view_layouts_base_html_head, :partial => 'time_trackers/assets'
end
