// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).on("click","#get_activities",function(event){
	
	
});

/***
@returns : ajax_promise
***/
var get_activities = function(done_function){
	var now = moment();
	var now_start = now.unix();
	var startDate = now.startOf("month");
	$.get( "/activities/get_activities",
	 	 { user_id: $("#user_data").data("resource").id, range: {from: startDate.unix(), to: now_start} , only:["image_url"]},
	 	 done_function,
	 	 "json"
	 	 );
}

/***
logic:
call the getactivities function after loading the calendar
on its done call, update the cell rows as needed.
***/
$(document).ready(function(){

	var transEndEventNames = {
		'WebkitTransition' : 'webkitTransitionEnd',
		'MozTransition' : 'transitionend',
		'OTransition' : 'oTransitionEnd',
		'msTransition' : 'MSTransitionEnd',
		'transition' : 'transitionend'
	},
	transEndEventName = transEndEventNames[ Modernizr.prefixed( 'transition' ) ],
	$wrapper = $( '#custom-inner' ),
	$calendar = $( '#calendar' ),
	cal = $calendar.calendario( {
		onDayClick : function( $el, $contentEl, dateProperties ){

				if( $contentEl.length > 0 ) {
					showEvents( $contentEl, dateProperties );
				}

			},
			caldata : codropsEvents,
			displayWeekAbbr : true
	} ),

	$month = $( '#custom-month' ).html( cal.getMonthName() ),
	$year = $( '#custom-year' ).html( cal.getYear() );
	$( '#custom-next' ).on( 'click', function() {
		cal.gotoNextMonth( updateMonthYear );
	} );
	$( '#custom-prev' ).on( 'click', function() {
		cal.gotoPreviousMonth( updateMonthYear );
	} );

	get_activities(function(data){
		console.log("the data is:");
		console.log(data);
		for(epoch in data){
			var dateStr = moment.utc(parseInt(epoch)*1000).format('MM-DD-YYYY');
			//get that particular datestr data-attribute
			var dateDiv = $("[data-strdate='" + dateStr +"']")[0];
			var activity = data[epoch];
			//now update the dateDiv as needed.	
			console.log("the activity image url is:" + activity["image_url"]);
			//$(dateDiv).css('background-image', 'url(' + activity["image_url"] + ')');
			$(dateDiv).html("<img class='calendar_day_background_image' src='" + activity["image_url"] + "'/>");
		}
	});



	function updateMonthYear() {				
		$month.html( cal.getMonthName() );
		$year.html( cal.getYear() );
	}

	// just an example..
	function showEvents( $contentEl, dateProperties ) {

		hideEvents();
		
		var $events = $( '<div id="custom-content-reveal" class="custom-content-reveal"><h4>Events for ' + dateProperties.monthname + ' ' + dateProperties.day + ', ' + dateProperties.year + '</h4></div>' ),
			$close = $( '<span class="custom-content-close"></span>' ).on( 'click', hideEvents );

		$events.append( $contentEl.html() , $close ).insertAfter( $wrapper );
		
		setTimeout( function() {
			$events.css( 'top', '0%' );
		}, 25 );

	}
	function hideEvents() {

		var $events = $( '#custom-content-reveal' );
		if( $events.length > 0 ) {
			
			$events.css( 'top', '100%' );
			Modernizr.csstransitions ? $events.on( transEndEventName, function() { $( this ).remove(); } ) : $events.remove();

		}

	}
	
})

