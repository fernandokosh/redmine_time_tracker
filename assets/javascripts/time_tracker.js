
/*
 * This script updates the element 'id' with 'newContent' if the two contents differ
 */

var popup = null;


function updateElementIfChanged(id, newContent) {
    el = $(id);
    if (el.innerHTML != newContent) { el.update(newContent); }
}

function openPopup(elem, id, issue) {
	
  var url = "/time_trackers/popup_tracker";

	if (id != null)
		url += '?project_id=' + id;
  
	if(issue)
		url += '&issue_id=' + issue;
		
  if( !popup || popup.closed) {	
		var dim = $(elem).readAttribute('rel').split(':');
		var s = 'width=' + dim[0] + ',height=' + dim[1] + ',scrollbars=no';
    popup = window.open( url, "timeTracker", s );
  } else popup.focus();	
}