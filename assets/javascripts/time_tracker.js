function hideMultiFormButtons(button_class) {
    var last = $('input.' + button_class).parent().parent().last().index();

    $('input.' + button_class).each(function (a, b) {
        if (last != $(this).parent().parent().index()) {
            $(this).hide();
        } else {
            $(this).show();
        }
    });
}

// ================== validation helpers ============================

function input_validator(name) {
    var start_field = $("#" + name + "_start_time");
    var stop_field = $("#" + name + "_stop_time");
    var spent_field = $("#" + name + "_spent_time");
    var proj_id_field = $("#" + name + "_project_id");
    var proj_select = $("#" + name + "_project_id_select");

    var max_time_field = $("#" + name + "_max_time");
    var min_time_field = $("#" + name + "_min_time");
    var max_spent_time_field = $("#" + name + "_max_spent_time");

    var start = timeString2sec(start_field.val());
    var stop = timeString2sec(stop_field.val());
    var spent_time = timeString2sec(spent_field.val());
    var max_time = timeString2sec(max_time_field.val());
    var min_time = timeString2sec(min_time_field.val());
    var max_spent_time = timeString2sec(max_spent_time_field.val());
    var proj_id = proj_id_field.val();

    if (spent_time > max_spent_time) {
        spent_field.addClass('invalid');
    } else {
        spent_field.removeClass('invalid');
    }

    if (proj_id == "") {
        proj_select.addClass('invalid');
        proj_id_field.addClass('invalid');
    }else{
        proj_select.removeClass('invalid');
        proj_id_field.removeClass('invalid');
    }

    var date_field = $("#" + name + "_tt_booking_date"); // exists only in edit-bookings-form
    if (date_field.length > 0) {
        var valid_dates_field = $("#" + name + "_valid_dates"); // exists only in edit-bookings-form
        var date = date_field.val();
        var valid_dates = valid_dates_field.val().split(" ");

        date_field.addClass('invalid');
        $.each(valid_dates, function (key, value) {
            if (value == date) {
                date_field.removeClass('invalid');
            }
        });
    }

    // if the stop-time looks smaller than the start-time, we assume a booking over midnight
    var om = false;
    if (min_time > max_time) {
        om = true;
    }

    // first statement checks for over-midnight booking | second one checks normal boundaries
    if (om && start < min_time && start > max_time || !om && (start < min_time || start > max_time)) {
        start_field.addClass('invalid');
    } else {
        start_field.removeClass('invalid');
    }

    if (om && stop < min_time && stop > max_time || !om && (stop < min_time || stop > max_time)) {
        stop_field.addClass('invalid');
    } else {
        stop_field.removeClass('invalid');
    }
//    }

    var invalid = false;
    start_field.parents('form:first').find('input').each(function () {
        if ($(this).hasClass('invalid')) {
            invalid = true;
        }
    });

    start_field.parents('form:first').find(':submit').attr('disabled', invalid);
}

// ================== booking_form helpers ============================

function updateBookingHours(name) {
    var start_field = $("#" + name + "_start_time");
    var stop_field = $("#" + name + "_stop_time");
    var spent_field = $("#" + name + "_spent_time");

    var start = start_field.val();
    var stop = stop_field.val();
    // if the stop-time looks smaller than the start-time, we assume a booking over midnight
    if (timeString2sec(stop) < timeString2sec(start)) {
        var temp = calcBookingHelper(start, "24:00", 1);
        spent_field.val(calcBookingHelper(stop, temp, 2));
    } else {
        spent_field.val(calcBookingHelper(start, stop, 1));
    }
    input_validator(name);
}

function updateBookingStop(name) {
    var start_field = $("#" + name + "_start_time");
    var stop_field = $("#" + name + "_stop_time");
    var spent_field = $("#" + name + "_spent_time");

    stop_field.val(calcBookingHelper(start_field.val(), spent_field.val(), 2));
    input_validator(name);
}

function updateBookingProject(name) {
    var issue_id_field = $("#" + name + "_issue_id");
    var project_id_field = $("#" + name + "_project_id");
    var project_id_select = $("#" + name + "_project_id_select");

    var issue_id = issue_id_field.val();
    // check if the string is blank
    if (!issue_id || $.trim(issue_id) === "") {
        project_id_select.attr('disabled', false);
        issue_id_field.removeClass('invalid');
        input_validator(name);
    } else {
        $.ajax({url:'/issues/' + issue_id + '.json',
            type:'GET',
            success:function (transport) {
                issue_id_field.removeClass('invalid');
                var issue = transport.issue;
                if (issue == null) {
                    project_id_select.attr('disabled', false);
                } else {
                    project_id_select.attr('disabled', true);
                    project_id_field.val(issue.project.id);
                    $("#" + project_id_select.attr("id")).val(issue.project.id);
                }
            },
            error:function () {
                project_id_select.attr('disabled', false);
                issue_id_field.addClass('invalid');
            },
            complete:function () {
                input_validator(name);
            }
        });
    }
}

function timeString2sec(str) {
    if (str.match(/\d\d?:\d\d?:\d\d?/)) {     //parse general input form hh:mm:ss
        var arr = str.trim().split(':');
        return new Number(arr[0]) * 3600 + new Number(arr[1]) * 60 + new Number(arr[2]);
    }
    if (str.match(/\d\d?:\d\d?/)) {     //parse general input form hh:mm:ss
        var arr = str.trim().split(':');
        return new Number(arr[0]) * 3600 + new Number(arr[1]) * 60;
    }
    // more flexible parsing for inputs like:  12d 23sec 5min
    var time_factor = {"s":1, "sec":1, "m":60, "min":60, "h":3600, "d":86400};
    var sec = 0;
    var time_arr = str.match(/\d+\s*\D+/g);
    jQuery.each(time_arr, function (index, item) {
        item = item.trim();
        var num = item.match(/\d+/);
        var fac = item.match(/\D+/)[0].trim().toLowerCase();
        if (time_factor[fac]) {
            sec += num * time_factor[fac];
        }
    });
    return sec;
}

function calcBookingHelper(ele1, ele2, calc) {
    var sec1 = timeString2sec(ele1);
    var sec2 = timeString2sec(ele2);
    if (calc == 1) {
        var val = sec2 - sec1;
    }
    if (calc == 2) {
        val = sec1 + sec2;
    }
    var h = Math.floor(val / 3600);
    var m = Math.floor((val - h * 3600) / 60);
    var s = Math.floor(val - (h * 3600 + m * 60));
    h < 10 ? h = "0" + h.toString() : h = h.toString();
    m < 10 ? m = "0" + m.toString() : m = m.toString();
    s < 10 ? s = "0" + s.toString() : s = s.toString();
    while (calc == 2 && h > 23) h = h - 24;    //stop_time should be between 0-24 o clock
    return h + ":" + m + ":" + s;
}
