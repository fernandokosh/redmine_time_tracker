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

Element.addMethods("SELECT", (function() {
    function getSelectedOptionHTML(element) {
        if (!(element = $(element))) return;
        var index = element.selectedIndex;
        return index >= 0 ? element.options[index].innerHTML : undefined;
    }

    return {
        getSelectedOptionHTML: getSelectedOptionHTML
    };
})());


var ac = null;


function observeIssueField(url) {

	if (ac === null) {
		ac = new Ajax.Autocompleter('issue_id',
		'issue_candidates',
		url,
		{ minChars: 3,
			frequency: 0.5,
			paramName: 'q',
			updateElement: function(value) {
				setCurrentIssue(value.id, $(value).innerHTML);
				$('issue_id').clear();
		}});		
	} else {
		ac.url = url;
	}
}

function updateTime(pe) {
	
	Ajax.activeRequestCount--;
	
	new Ajax.Request('/time_trackers/get_current_time', {
		asynchronous: true,
		onSuccess: function(transport) {
			
			var json = transport.responseText.evalJSON();
			
			try {
				$('current_time').update(json.spent_time);
			} catch (e) {
			}
		}				
	});
}

function startTimer(interval) {
	
	var id = getCurrentIssue();
	
	if ( id == null) {
		alert('select an issue first');
		return false;
	}

	new Ajax.Request('/time_trackers/start?issue_id=' + id, {
		
		onSuccess: function(response) {
			updateParent();
			disableControls();
		}		
		
	});
	
  startUpdater(interval);
	return true;
	
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
			updateParent();
			pe.stop();
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
	$('issue_id').disabled = false;
	
}

function disableControls () {
	
	$('project_select').disabled = true;
	$('issues').disabled = true;
	$('issue_id').disabled = true;
	
}

function showAC(id) {
	observeIssueField('/issues/auto_complete?project_id=' + id);
	$('autocompleter').removeClassName('hidden');			
}


function setCurrentIssue (id, subject) {

	$('current_issue').update(subject).writeAttribute('rel', id);
	
}

function deselectCurrentIssue () {
	
	$cur = $('current_issue');
	$str = $cur.next().readAttribute('rel');
	$cur.update($str).removeAttribute('rel');	
}

function getCurrentIssue () {
	
	if (!$('current_issue').hasAttribute('rel'))
		return null;
		
	var current = $('current_issue').readAttribute('rel');
	
	current = parseInt(current);
	
	if (typeof(current) == 'number' && isFinite(current))
		return current;
		
	return null;

}

function observeIssues () {
	
	$('issues').observe('change', function() {
		var id = $F(this);
		
		if (id == 0) {
			deselectCurrentIssue();
			return;
		}
		setCurrentIssue(id, this.getSelectedOptionHTML());
	});
	
}

document.observe('dom:loaded', function () {
		
		
	observeIssues();
	
	$('project_select').observe('change', function() {		
		
		var id = $F(this);		
		if (id == '') {
			return;
		}		
		
		$('issue_id').clear();
		updateParent();
		showAC(id);
		new Ajax.Replacer('issues', '/time_trackers/get_issues', {
			parameters: { project_id: id },
			onComplete: function() {
				observeIssues();
				deselectCurrentIssue();
			}
		});
		new Ajax.Replacer('activities', '/time_trackers/get_activities', {parameters: { project_id: id}});		

		
	});
	
	$startButton = $('start-stop-button');
	
	if ($startButton.hasClassName('running')) {		
		disableControls();
		startUpdater($('intervalHolder').readAttribute('rel'));
	} 
	
	$startButton.observe('click', function() {
		
		if( this.hasClassName('running') == false) {
			
			if (startTimer($('intervalHolder').readAttribute('rel')) == false)
				return;
				
			this.update('Stop');
			
		} else {
			
			this.update('Start')			
			stopTimer();
		}
		
		this.toggleClassName('running');
		
	});	
});