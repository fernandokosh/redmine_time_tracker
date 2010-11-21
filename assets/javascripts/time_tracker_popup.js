Ajax.Replacer = Class.create(Ajax.Updater, {
  initialize: function($super, container, url, options) {
    options = options || { };
    options.onComplete = (options.onComplete ||
Prototype.emptyFunction)
      .wrap(function(proceed, transport, json) {
        $(container).replace(transport.responseText);
        proceed(transport, json);
      })
    $super(container, url, options);
  }
});

function updateTime(pe) {
	
	
}

function startTimer(interval) {
	
	var id = $F($('issues'));
	
	if ( id == 'Select a project') {
		alert('select an issue first');
		return;
	}

	new Ajax.Request('/time_trackers/start?issue_id=' + id, {
		
		onSuccess: function(response) {
			updateParent();
			disableControls();
		}		
		
	});
	
  startUpdater(interval);
	
}

function startUpdater (interval) {
		
	pe = new PeriodicalExecuter(updateTime, interval);
}

function stopTimer() {
	
	new Ajax.Request('/time_trackers/stop_and_add', {
		method: 'post',
		parameters: { 
			comment: $F($('comment')),
			activity: $F($('activities'))
		},
		onSuccess: function(transport, json){			
			enableControls();
			$('comment').clear();
			showAutocompleter($F($('project_select')));
		}
	});
	
}

function updateParent() {	
	if (opener && typeof opener.updateTimeTrackerMenu == 'function')
		opener.updateTimeTrackerMenu();
}


function enableControls () {

	$('project_select').disabled = false;
	$('issues').disabled = false;
	
}

function disableControls () {
	
	$('project_select').disabled = true;
	$('issues').disabled = true;
	
}

function showAutocompleter(id) {
	observeParentIssueField('/issues/auto_complete?project_id=' + id);
	$('autocompleter').removeClassName('hidden');			
}

document.observe('dom:loaded', function () {
		
	$('project_select').observe('change', function() {		
		
		var id = $F(this);		
		if (id == '') {
			return;
		}		
		updateParent();
		showAutocompleter(id);
		new Ajax.Replacer('issues', '/time_trackers/get_issues', {parameters: { project_id: id}});
		new Ajax.Replacer('activities', '/time_trackers/get_activities', {parameters: { project_id: id}});		
		
	});
	
	$startButton = $('start-stop-button');
	
	if ($startButton.hasClassName('running')) {		
		disableControls();
		startUpdater($('intervalHolder').readAttribute('rel'));
	} else {
		console.log('not running');
	}
	
	$startButton.observe('click', function() {
		
		if( this.hasClassName('running') == false) {
			this.update('Stop')						
			startTimer($('intervalHolder').readAttribute('rel'));
		} else {
			
			this.update('Start')			
			stopTimer();
		}
		
		this.toggleClassName('running');
		
	});	
});