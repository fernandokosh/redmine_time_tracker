# This class hooks into Redmine's View Listeners in order to add content to the page
class TimeTrackerHooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_body_bottom, :partial => 'time_trackers/update_menu'
    render_on :view_issues_context_menu_start, :partial => 'time_trackers/update_context'

    def view_layouts_base_html_head(context = {})
        css = stylesheet_link_tag 'time_tracker.css', :plugin => 'redmine_time_tracker'
        js = javascript_include_tag 'time_tracker.js', :plugin => 'redmine_time_tracker'
        css + js
    end
end
