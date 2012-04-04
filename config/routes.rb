ActionController::Routing::Routes.draw do |map|
  map.connect '/time_trackers/stop', :controller => 'time_trackers', :action => 'stop'
  map.connect '/time_trackers/start', :controller => 'time_trackers', :action => 'start'
  map.connect '/time_trackers/suspend', :controller => 'time_trackers', :action => 'suspend'
  map.connect '/time_trackers/resume', :controller => 'time_trackers', :action => 'resume'
  map.connect '/time_trackers/render_menu', :controller => 'time_trackers', :action => 'render_menu'
  map.connect '/time_trackers/show_report', :controller => 'time_trackers', :action => 'show_report'
  map.connect '/time_trackers/delete', :controller => 'time_trackers', :action => 'delete'
  map.connect '/time_trackers', :controller => 'time_trackers', :action => 'index'
end
