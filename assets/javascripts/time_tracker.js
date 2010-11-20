
/*
 * This script updates the element 'id' with 'newContent' if the two contents differ
 */
function updateElementIfChanged(id, newContent) {
    el = $(id);
    if (el.innerHTML != newContent) { el.update(newContent); }
}

function openPopup() {
	
	window.open('/time_trackers/popup_tracker','Titel PopUp','width=500,height=500,scrollbars');
	
}