$ ->
 $('.tt_list').on 'change', 'input, select', ->
   time_log_id = $(@).closest('td').data('entry-id')
   (new redmine_time_tracker.AddBookingValidator("time_log_add_booking_#{time_log_id}")).validate();