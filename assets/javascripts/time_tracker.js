
/*
 * This script updates the element 'id' with 'newContent' if the two contents differ
 */

var popup = null;


function updateElementIfChanged(id, newContent) {
    el = $(id);
    if (el.innerHTML != newContent) { el.update(newContent); }
}

function openPopup() {
	
  var url = "/time_trackers/popup_tracker";
  
  if( !popup || popup.closed) {
    popup = window.open( url, "timeTracker", 'height=500,width=450,scrollbars=no' );
  } else popup.focus();	
	
//	window.open('/time_trackers/popup_tracker','Titel PopUp','width=500,height=500,scrollbars');
	
}