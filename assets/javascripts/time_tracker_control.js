// ================== time_tracker_controller helpers ============================
function updateTTControllerForm(obj) {
    if (obj.nodeName == "FORM") {
        var form = obj;
        $.ajax({url:'time_trackers/update.json?' + $("#" + form.id).serialize(),
            type:'PUT',
            success:function (transport) {
                var tt = transport.time_tracker;
                form.time_tracker_issue_id.value = tt.issue_id;
                (tt.issue_id == null) ? $(form.project_id_select).attr('disabled', false) : $(form.project_id_select).attr('disabled', true);
                form.time_tracker_comments.value = tt.comments;
                form.time_tracker_project_id.value = tt.project_id;
                select_options = form.project_id_select;
                if (tt.project_id == null) {
                    select_options[0].selected = true;
                } else {
                    for (i = 0; i < select_options.length; i++) {
                        if (select_options[i].value == tt.project_id) select_options[i].selected = true;
                    }
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
        // TODO this part is not tested to be jquery-compatible yet
        // function is called from the calendar widget. the calendar could only send a reference to itself, so we have
        // to find the form manually..
        var cal = obj;
        var form = cal.params.inputField.form;
        updateTTControllerForm(form);
    }
}

// ================== time_tracker_control add auto-completers ============================
$(function () {
    $('#time_tracker_issue_id').autocomplete({
        source:'tt_completer/get_issue.json',
        minLength:0,
        select:function (event, ui) {
            $('#time_tracker_comments').val(ui.item.data);
            $('#time_tracker_comments').change();
        }
    });
});

$(function () {
    $('#time_tracker_comments').autocomplete({
        source:'tt_completer/get_issue.json',
        minLength:0,
        select:function (event, ui) {
            if (this.form.id == "new_time_tracker") {
                event.preventDefault();
                $(this).val(ui.item.label);
            } else {
                $('#time_tracker_issue_id').val(ui.item.value);
                $('#time_tracker_comments').val(ui.item.data);
                $('#time_tracker_comments').change();
            }
        }
    });
});
