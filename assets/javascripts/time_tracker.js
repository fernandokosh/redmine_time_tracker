/*
 * This script updates the element 'id' with 'newContent' if the two contents differ
 */
function updateElementIfChanged(id, newContent) {
    el = $(id);
    if (el.innerHTML != newContent) {
        el.update(newContent);
    }
}

// ================== time_tracker_controller helpers ============================

function updateTTControllerForm(obj) {
    if (obj.nodeName == "FORM") {
        var form = obj;
        new Ajax.Request('/time_trackers/update.json?' + Form.serializeElements(form.getInputs()),
            {
                method:'put',
                onSuccess:function (transport) {
                    var tt = transport.responseJSON.time_tracker;
                    form.time_tracker_issue_id.value = tt.issue_id;
                    (tt.issue_id == null) ? form.project_id_select.enable() : form.project_id_select.disable();
                    form.time_tracker_comments.value = tt.comments;
                    form.time_tracker_project_id.value = tt.project_id;
                    select_options = form.project_id_select;
                    for (i = 0; i < select_options.length; i++) {
                        if (select_options[i].value == tt.project_id) select_options[i].selected = true;
                    }
                    dat = new Date(Date.parse(tt.started_on));
                    //form.time_tracker_start_time.value = dat.getHours().toString()+':'+dat.getMinutes().toString();
                    form.time_tracker_start_time.value = dat.toLocaleTimeString();
                    year = dat.getFullYear().toString();
                    month = dat.getMonth() + 1;
                    (month < 10) ? month = '0' + month.toString() : month = month.toString();
                    day = dat.getDate();
                    (day < 10) ? day = '0' + dat.getDate().toString() : day = dat.getDate().toString();
                    form.time_tracker_date.value = year + '-' + month + '-' + day;
                }
            });
    } else {
        // function is called from the calendar widget. the calendar could only send a reference to itself, so we have
        // to find the form manually..
        var cal = obj;
        var form = cal.params.inputField.parentElement.parentElement.parentElement.parentElement;
        updateTTControllerForm(form);
    }
}

// ================== booking_form helpers ============================

function updateBookingHours(form) {
    start = form.time_log_start_time.value;
    stop = form.time_log_stop_time.value;
    if (timeString2sec(stop) < timeString2sec(start)) {
        swap = start;
        start = stop;
        stop = swap;
        form.time_log_start_time.value = start;
        form.time_log_stop_time.value = stop;
    }
    form.time_log_spent_time.value = calcBookingHelper(start, stop, 1);
}

function updateBookingStop(form) {
    form.time_log_stop_time.value = calcBookingHelper(form.time_log_start_time.value, form.time_log_spent_time.value, 2);
}

function updateBookingProject(form) {
    issue_id = form.time_log_issue_id.value;
    if (issue_id.blank()) {
        form.project_id_select.enable();
        form.time_log_issue_id.parentNode.removeClassName('invalid');
    } else {
        new Ajax.Request('/issues/' + issue_id + '.json?',
            {
                method:'get',
                onSuccess:function (transport) {
                    form.time_log_issue_id.parentNode.removeClassName('invalid');
                    var issue = transport.responseJSON.issue;
                    if (issue == null) {
                        form.project_id_select.enable();
                    } else {
                        form.project_id_select.disable();
                        form.time_log_project_id.value = issue.project.id;
                        select_options = form.project_id_select;
                        for (i = 0; i < select_options.length; i++) {
                            if (select_options[i].value == issue.project.id) select_options[i].selected = true;
                        }
                    }
                },
                onFailure:function () {
                    form.project_id_select.enable();
                    form.time_log_issue_id.parentNode.addClassName('invalid');
                }
            });
    }
}

function timeString2sec(str) {
    if (str.match(/\d\d?:\d\d?:\d\d?/)) {     //parse general input form hh:mm:ss
        var arr = str.strip().split(':');
        return new Number(arr[0]) * 3600 + new Number(arr[1]) * 60 + new Number(arr[2]);
    }
    if (str.match(/\d\d?:\d\d?/)) {     //parse general input form hh:mm:ss
        var arr = str.strip().split(':');
        return new Number(arr[0]) * 3600 + new Number(arr[1]) * 60;
    }
    // more flexible parsing for inputs like:  12d 23sec 5min
    var time_factor = new Hash({"s":1, "sec":1, "m":60, "min":60, "h":3600, "d":86400});
    var sec = 0;
    var time_arr = str.match(/\d+\s*\D+/g);
    time_arr.each(function (item) {
        item = item.strip();
        var num = item.match(/\d+/);
        var fac = item.match(/\D+/);
        if (time_factor.get(fac)) {
            sec += num * time_factor.get(fac);
        }
    });
    return sec;
}

function calcBookingHelper(ele1, ele2, calc) {
    sec1 = timeString2sec(ele1);
    sec2 = timeString2sec(ele2);
    if (calc == 1) {
        val = sec2 - sec1;
    }
    if (calc == 2) {
        val = sec1 + sec2;
    }
    h = (val / 3600).floor();
    m = ((val - h * 3600) / 60).floor();
    s = (val - (h * 3600 + m * 60)).floor();
    h < 10 ? h = "0" + h.toString() : h = h.toString();
    m < 10 ? m = "0" + m.toString() : m = m.toString();
    s < 10 ? s = "0" + s.toString() : s = s.toString();
    if (calc == 2 && h > 23) h = h - h / 24;    //stop_time should be between 0-24 o clock
    return h + ":" + m + ":" + s;
}
