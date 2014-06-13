@redmine_time_tracker ?= {}
class @redmine_time_tracker.TimeTracker
  @hideMultiFormButtons: (button_class) ->
    last = $("input.#{button_class}").parent().parent().last().index()
    $("input." + button_class).each ->
      unless last is $(@).parent().parent().index()
        $(this).hide()
      else
        $(this).show()

  @base_url: ->
    src = $("link[href*=\"time_tracker.css\"]")[0].href
    src.substr 0, src.indexOf("plugin_assets")

  @validate_time_tracker_form: ->
    proj_field = $ '#time_tracker_project_id'
    activity_select = $ '#time_tracker_activity_id'
    proj_id = proj_field.val()
    activity_id = activity_select.val()
    activity_select.toggleClass 'invalid', proj_id isnt "" and activity_id is ""
    $(".time-tracker-form :submit").attr "disabled", $(".time-tracker-form :input").hasClass("invalid")

  @validate_list_inputs: (name) ->
    start_field = $("#" + name + "_start_time")
    stop_field = $("#" + name + "_stop_time")
    spent_field = $("#" + name + "_spent_time")
    proj_id_field = $("#" + name + "_project_id")
    proj_select = $("#" + name + "_project_id_select")
    activity_select = $("#" + name + "_activity_id_select")

    max_time_field = $("#" + name + "_max_time")
    min_time_field = $("#" + name + "_min_time")
    max_spent_time_field = $("#" + name + "_max_spent_time")

    start = timeString2min(start_field.val())
    stop = timeString2min(stop_field.val())
    spent_time = timeString2min(spent_field.val())
    max_time = (if max_time_field.length isnt 0 then timeString2min(max_time_field.val()) else null)
    min_time = (if min_time_field.length isnt 0 then timeString2min(min_time_field.val()) else null)
    max_spent_time = (if max_spent_time_field.length isnt 0 then timeString2min(max_spent_time_field.val()) else null)

    spent_field.toggleClass "invalid", max_spent_time isnt null and spent_time > max_spent_time
    proj_select.toggleClass "invalid", proj_id_field.val() is ""
    proj_id_field.toggleClass "invalid", proj_id_field.val() is ""
    activity_select.toggleClass "invalid", activity_select.val() is ""

    date_field = $("#" + name + "_tt_booking_date") # exists only in edit-bookings-form
    if date_field.length > 0
      valid_dates = $("#" + name + "_valid_dates").val().split("|")
      date_field.toggleClass "invalid", $.inArray(date_field.val(), valid_dates) is -1
    if max_time isnt null and min_time isnt null and max_spent_time < 1440

      # if the stop-time looks smaller than the start-time, we assume a booking over midnight
      om = false
      om = true  if min_time > max_time

      # first statement checks for over-midnight booking | second one checks normal boundaries
      start_field.toggleClass "invalid", om and start < min_time and start > max_time or not om and (start < min_time or start > max_time)
      stop_field.toggleClass "invalid", om and stop < min_time and stop > max_time or not om and (stop < min_time or stop > max_time)
    max_spent_time_field.toggleClass "invalid", spent_time > max_spent_time if max_spent_time isnt null
    start_field.parents("form:first").find(":submit").attr "disabled", start_field.parents("form:first").find(":input").hasClass("invalid")

  @updateBookingHours: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    stop = timeString2min($("#" + name + "_stop_time").val())

    # if the stop-time is smaller than the start-time, we assume a booking over midnight
    $("#" + name + "_spent_time").val min2timeString(stop + ((if stop < start then 1440 else 0)) - start)
    @validate_list_inputs name

  @updateBookingStop: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    spent_time = timeString2min($("#" + name + "_spent_time").val())
    $("#" + name + "_stop_time").val min2parsedTimeString((start + spent_time) % 1440)
    @validate_list_inputs name

  @updateBookingProject: (api_key, name) ->
    issue_id_field = $("#" + name + "_issue_id")
    project_id_field = $("#" + name + "_project_id")
    project_id_select = $("#" + name + "_project_id_select")
    issue_id = issue_id_field.val()

    # check if the string is blank
    if not issue_id or $.trim(issue_id) is ""
      project_id_select.attr "disabled", false
      issue_id_field.removeClass "invalid"
      @validate_list_inputs name
    else
      $.ajax
        url: @base_url() + "issues/" + issue_id + ".json?key=" + api_key
        type: "GET"
        success: (transport) =>
          issue_id_field.removeClass "invalid"
          issue = transport.issue
          unless issue?
            project_id_select.attr "disabled", false
          else
            project_id_select.attr "disabled", true
            project_id_field.val issue.project.id
            $("#" + project_id_select.attr("id")).val issue.project.id
          @updateBookingActivity api_key, name

        error: ->
          project_id_select.attr "disabled", false
          issue_id_field.addClass "invalid"

        complete: =>
          @validate_list_inputs name

  @updateBookingActivity: (api_key, name) ->
    $.ajax
      url: @base_url() + "tt_completer/get_activity.json?key=" + api_key + "&project_id=" + $("#" + name + "_project_id").val()
      type: "GET"
      success: (activites) =>
        activity_field = $("#" + name + "_activity_id_select")
        selected_activity = activity_field.find("option:selected").text()
        activity_field.find("option[value!=\"\"]").remove()
        $.each activites, (i, activity) ->
          activity_field.append "<option value=\"" + activity.id + "\">" + activity.name + "</option>"
          activity_field.val activity.id  if selected_activity is activity.name

        @validate_list_inputs name

$ ->
  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html
  redmine_time_tracker.TimeTracker.validate_time_tracker_form()