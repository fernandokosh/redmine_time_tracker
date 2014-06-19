@redmine_time_tracker ?= {}
class @redmine_time_tracker.FormValidator
  constructor: (@form)->

  validate: ->
    @_clean_up()
    @_do_validation()
    @_update_submit_button_state()

  _do_validation: ->
    #do stuff

  _clean_up: ->
    @_invalid_form_inputs().removeClass 'invalid'

  _validates_presence_of: (element) ->
    @_validates element, element.val() isnt ''

  _validates: (element, condition) ->
    element.addClass 'invalid' unless condition

  _form_is_invalid: ->
    @_invalid_form_inputs().length > 0

  _invalid_form_inputs: ->
    @form.find(':input.invalid')

  _update_submit_button_state: ->
    @form.find(':submit').attr 'disabled', @_form_is_invalid()

class @redmine_time_tracker.ListInputValidator extends @redmine_time_tracker.FormValidator
  constructor: (name)->
    @start_field = $("#" + name + "_start_time")
    @stop_field = $("#" + name + "_stop_time")
    @spent_field = $("#" + name + "_spent_time")
    super @start_field.closest "form"

  _do_validation: ->
    @_validates_presence_of @start_field
    @_validates_presence_of @stop_field
    @_validates_presence_of @spent_field
    super

class @redmine_time_tracker.EditTimeLogValidator extends @redmine_time_tracker.ListInputValidator
  constructor: (name) ->
    @date_field = $("#" + name + "_tt_log_date")
    super name

  _do_validation: () ->
    @_validates_presence_of @date_field
    super

class @redmine_time_tracker.AddBookingValidator extends @redmine_time_tracker.ListInputValidator
  constructor: (name) ->
    @proj_id_field = $("#" + name + "_project_id")
    @proj_select = $("#" + name + "_project_id_select")
    @activity_select = $("#" + name + "_activity_id_select")
    @max_time_field = $("#" + name + "_max_time")
    @min_time_field = $("#" + name + "_min_time")
    @max_spent_time_field = $("#" + name + "_max_spent_time")
    super name

  _do_validation: () ->
    @_validates_presence_of @proj_select
    @_validates_presence_of @activity_select

    start = timeString2min(@start_field.val())
    min_time = timeString2min(@min_time_field.val())
    stop = timeString2min(@stop_field.val())
    max_time = timeString2min(@max_time_field.val())
    spent_time = timeString2min(@spent_field.val())
    max_spent_time = timeString2min(@max_spent_time_field.val())

    @_validates @spent_field, spent_time <= max_spent_time
    if max_spent_time < 1440
      if min_time > max_time
        @_validates @start_field, not (max_time <= start < min_time)
        @_validates @stop_field, not (max_time < stop <= min_time)
      else
        @_validates @start_field, min_time <= start < max_time
        @_validates @stop_field, min_time < stop <= max_time
    super

class @redmine_time_tracker.EditBookingValidator extends @redmine_time_tracker.AddBookingValidator
  constructor: (name) ->
    @date_field = $("#" + name + "_tt_booking_date")
    @valid_dates = $("#" + name + "_valid_dates").val().split("|")
    super name

  _do_validation: () ->
    @_validates_presence_of @date_field
    @_validates @date_field, not ($.inArray(@date_field.val(), @valid_dates) is -1)
    super

class @redmine_time_tracker.TimeTrackerFormValidator extends @redmine_time_tracker.FormValidator
  constructor: ->
    @proj_field = $('#time_tracker_project_id')
    @activity_select = $('#time_tracker_activity_id')
    super $('.time-tracker-form')

  _do_validation: () ->
    proj_id = @proj_field.val()
    activity_id = @activity_select.val()
    @_validates @activity_select, proj_id is "" or activity_id isnt ""
    super