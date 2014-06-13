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

$ ->
  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html

  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html

  $(document).on "ajax:success", ".tt_stop, .tt_start, .tt_dialog_stop", (xhr, html, status) ->
    $("#content .flash").remove()
    $("#content").prepend html