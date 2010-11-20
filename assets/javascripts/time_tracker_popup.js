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

function startTimer() {
	
	var id = $F($('issues'));
	
	if ( id == 'Select a project') {
		alert('select an issue first');
		return;
	}

	new Ajax.Request('/time_trackers/start?issue_id=' + id, {
		
		onSuccess: function(response) {
			alert('success');	
		}
		
	});
	
  pe = new PeriodicalExecuter(updateTime, 1);
	
}

function stopTimer() {
	
	new Ajax.Request('/time_trackers/stop_and_add', {
		method: 'post',
		parameters: { 
			comment: $F($('comment')),
			activity: $F($('activities'))
		},
		onSuccess: function(transport, json){
			
			if (!json)
				return;
				
			alert(json.result);
				
		}
	});
	
}

document.observe('dom:loaded', function () {
	
	
	$('projects').observe('change', function() {
		
		new Ajax.Replacer('issues', '/time_trackers/get_issues', {parameters: { project_id: $F(this)}});
		new Ajax.Replacer('activities', '/time_trackers/get_activities', {parameters: { project_id: $F(this)}});		
		
	});
	
	
	$('start-stop-button').observe('click', function() {
		
		if( this.hasClassName('running') == false) {
			this.update('Stop')						
			startTimer();
		} else {
			
			this.update('Start')			
			stopTimer();
		}
		
		this.toggleClassName('running');

		
	});
	
	
	
});