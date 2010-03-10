# This class hooks into Redmine's View Listeners in order to add content to the page
class TimeTrackerHooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_body_bottom, :partial => 'time_trackers/update_menu'

    def view_layouts_base_html_head(context = {})
        '<style type="text/css">
            body #time-tracker-menu { margin-right: 8px; }
            body #time-tracker-menu a { margin-right: 0px; }
        </style>'
    end
end

