$ ->
 $('.tt_list').on 'change', '[data-validator] input, select', ->
   $field_wrapper = $(@).closest('td')
   (new redmine_time_tracker[$field_wrapper.data('validator')]($field_wrapper.data('name'))).validate();