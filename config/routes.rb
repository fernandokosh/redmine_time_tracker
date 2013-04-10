match '/time_bookings/actions', :to => 'time_bookings#actions', :via => [:get, :post, :put]
match '/time_bookings/show_edit', :to => 'time_bookings#show_edit', :via => [:get, :post]
match '/time_bookings/delete', :to => 'time_bookings#delete', :via => [:get, :post]
match '/time_bookings/get_list_entry', :to => 'time_bookings#get_list_entry', :via => [:get, :post]

match '/time_logs/actions', :to => 'time_logs#actions', :via => [:get, :post, :put]
match '/time_logs/delete', :to => 'time_logs#delete', :via => [:get, :post]
match '/time_logs/show_booking', :to => 'time_logs#show_booking', :via => [:get, :post]
match '/time_logs/show_edit', :to => 'time_logs#show_edit', :via => [:get, :post]
match '/time_logs/get_list_entry', :to => 'time_logs#get_list_entry', :via => [:get, :post]

match '/tt_overview', :to => 'tt_overview#index', :via => [:get, :post]

match '/time_trackers/stop', :to => 'time_trackers#stop', :via => [:get, :put, :post]
match '/time_trackers/start', :to => 'time_trackers#start', :via => [:post, :get]
match '/time_trackers/update', :to => 'time_trackers#update', :via => [:get, :put]
match '/time_trackers/delete', :to => 'time_trackers#delete', :via => [:get, :post]

match '/tt_bookings_list', :to => 'tt_bookings_list#index', :via => [:get, :post]
match '/tt_info', :to => 'tt_info#index', :via => [:get, :post]
match '/tt_logs_list', :to => 'tt_logs_list#index', :via => [:get, :post]
match '/tt_print_report', :to => 'tt_reporting#print_report', :via => [:get]
match '/tt_reporting', :to => 'tt_reporting#index', :via => [:get, :post]

#helpers
match '/tt_completer/get_issue', :to => 'tt_completer#get_issue', :via => [:get]
match '/tt_completer/get_issue_id', :to => 'tt_completer#get_issue_id', :via => [:get]
match '/tt_completer/get_issue_subject', :to => 'tt_completer#get_issue_subject', :via => [:get]

match '/tt_date_shifter/get_prev_time_span', :to => 'tt_date_shifter#get_prev_time_span', :via => [:get]
match '/tt_date_shifter/get_next_time_span', :to => 'tt_date_shifter#get_next_time_span', :via => [:get]

match '/tt_menu_switcher/index', :to => 'tt_menu_switcher#index', :via => [:get]

# context menus
match '/tt_overview/context_menu', :to => 'context_menus#tt_overview', :as => 'tt_overview_context_menu'
match '/tt_bookings_list/context_menu', :to => 'context_menus#tt_bookings_list', :as => 'tt_bookings_list_context_menu'
match '/tt_logs_list/context_menu', :to => 'context_menus#tt_logs_list', :as => 'tt_logs_list_context_menu'
