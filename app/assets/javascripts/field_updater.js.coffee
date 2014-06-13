@redmine_time_tracker ?= {}
class @redmine_time_tracker.FieldUpdater
  @updateBookingHours: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    stop = timeString2min($("#" + name + "_stop_time").val())

    # if the stop-time is smaller than the start-time, we assume a booking over midnight
    $("#" + name + "_spent_time").val min2timeString(stop + ((if stop < start then 1440 else 0)) - start)

  @updateBookingStop: (name) ->
    start = timeString2min($("#" + name + "_start_time").val())
    spent_time = timeString2min($("#" + name + "_spent_time").val())
    $("#" + name + "_stop_time").val min2parsedTimeString((start + spent_time) % 1440)

  @updateBookingProject: (name) ->
    issue_id_field = $("#" + name + "_issue_id")
    project_id_field = $("#" + name + "_project_id")
    project_id_select = $("#" + name + "_project_id_select")
    issue_id = issue_id_field.val()

    # check if the string is blank
    if not issue_id or $.trim(issue_id) is ""
      project_id_select.attr "disabled", false
      issue_id_field.removeClass "invalid"
    else
      $.ajax
        url: redmine_time_tracker.TimeTracker.base_url() + "issues/" + issue_id + ".json?key=" + current_user_api_key()
        type: "GET"
        success: (transport) =>
          issue_id_field.removeClass "invalid"
          issue = transport.issue
          unless issue?
            project_id_select.attr "disabled", false
          else
            project_id_select.attr "disabled", true
            project_id_field.val issue.project.id
            $("#" + project_id_select.attr("id"))
            .val(issue.project.id)
            .trigger('change')
          @updateBookingActivity name

        error: ->
          project_id_select.attr "disabled", false
          issue_id_field.addClass "invalid"

  @updateBookingActivity: (name) ->
    $.ajax
      url: redmine_time_tracker.TimeTracker.base_url() + "tt_completer/get_activity.json?key=" + current_user_api_key() + "&project_id=" + $("#" + name + "_project_id").val()
      type: "GET"
      success: (activites) =>
        activity_field = $("#" + name + "_activity_id_select")
        selected_activity = activity_field.find("option:selected").text()
        activity_field.find("option[value!=\"\"]").remove()
        $.each activites, (i, activity) ->
          activity_field.append "<option value=\"" + activity.id + "\">" + activity.name + "</option>"
          activity_field.val activity.id  if selected_activity is activity.name