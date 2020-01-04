/***
HOW STUFF WORKS.
There are two scenarios that have to be covered.
a. the current month that loads when the page opens: 
	- for this purpose we have hooked into the basic constructor of the calendario object
	- there was an option inside calendario.js, in the _init function, inside which is called a _generateTemplate function. INside that function there is an option to call a callback function at the end of the _generateTemplate. 
	- so I have defined a custom function here in this file, and passed it in the options of the calendario instance, labelled as "callback".
	- this is then passed to the _generateTemplate function and called at the end of that function.
	- the callback defined in this file is "load_current_month".
b. the months that load when we click , prev/next
	- here we have hooked into the function called updateMonthYear.
	- here we just get the current_month and year, from calendario itself and use that to calculate the start moment and end moment.

Common pathway for both functions in the end is as follows:
call get_activities(callback, start_moment, end_moment)
->
this makes the ajax calls to the server, and returns the data to the callback function mentioned in the get_activities function call.
->
the callback defined in this file is "update_calendar_images_and_popups", which basically uses the data got back to update the individual date cells, based on the data-attribute, which we added in the calendario.js file.
->end.
***/

/***
WORDJELLY FUNCTION
@param done_function[fn] : the function to be called after the data is done loading.
@param start_moment[Moment] : a Moment.js object reflecting the start_point from when to get the activities
@param end_moment[Moment] : a Moment.js object reflecting the end_point upto which to get the activities.
@returns : the result of the $.get call.
***/
var get_activities = function(done_function,start_moment,end_moment){
	//if these are null then we will get inbuilt defaults from the server.
	$.get( "/get_activities",
	 	 { user_id: $("#user_data").data("resource").id, range: {from: start_moment.unix(), to: end_moment.unix()} , only:["image_url"]},
	 	 done_function,
	 	 "json"
	 	 );
}

/***
This should be called in the following style, wherever get_activities is called
first().then(second).then(third)
@param done_function[fn] : 
@param start_moment[Moment] : 
@returns : dateStrings of most active months, as an array
***/
var get_most_active_months = function(done_function,start_moment){

}

/***
WORDJELLY FUNCTION
The callback function for get_activities
@param data[Object] : object returned from server, from the get_activities call
@return: nil
***/
var update_calendar_images_and_popups = function(data){
	for(epoch in data){
		var dateStr = moment.utc(parseInt(epoch)*1000).format('MM-DD-YYYY');
		//get that particular datestr data-attribute
		var dateDiv = $("[data-strdate='" + dateStr +"']")[0];
		var activity = data[epoch];
		//now update the dateDiv as needed.	
		$(dateDiv).html("<span class='helper'></span><img class='calendar_day_background_image' src='" + activity["image_url"] + "'/>");
	}

}


/***
The callback function for the get_most_active_months
***/
var update_most_active_months_dots = function(data){
	//get the calendar div.
	//then add the dots.
	//fs-8
	//m-15-left
	//text-lighten or darken.
	$(".fc-body").append("<div class='center m-10-top m-20-bottom'><i class='fa fa-circle fs-8 teal-text text-lighten-5'></i><i class='fa fa-circle fs-8 m-15-left teal-text'></i><i class='fa fa-circle fs-8 m-15-left teal-text'></i><i class='fa fa-circle fs-8 m-15-left teal-text'></i><i class='fa fa-circle fs-8 m-15-left teal-text text-lighten-3'></i><i class='fa fa-circle fs-8 m-15-left teal-text text-lighten-1'></i><i class='fa fa-circle fs-8 m-15-left teal-text '></i></div>");
}

/***
pads the given number to the required number of digits.
@used_in : #updateMonthYear, to get the month number , correctly padded.
@param number[Integer] : the number we have 
@param digits[Integer] : required number of digits to pad it to.
@return[Integer] : the @number padded with zero's to get the number of @digits
***/
var padDigits = function(number, digits) {
    return Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number;
}


/***
called inside the jquery.calendario.js file.
calendar instance is passed into it, so that you can successfully determine the start date and end date.
whenever we do something.call , the current global object is passed in as "this" as the default argument.
so current_month_load is registered as "callback" property in the calendario instance, that was initialized above, and in the generate_template function inside calendario.js, it is passed in as the callback, and "called", so by default the calendario instance is passed to it(current_month_load function), and we use it to determine the start_momeht and end_moment.
@used_in : $calendario.calendario , below in this file, the basic constructor for the calendar object. This is used to populate the data for the month that loads by default on the page.
@param Calendario[Object] : the calendario instance
@return nil.
***/
var current_month_load = function(){
	var base_moment = moment(this.today);
	var start_moment = base_moment.startOf("month");
	var end_moment = base_moment.endOf("month");
	get_activities(update_calendar_images_and_popups,start_moment,end_moment);
}

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
			displayWeekAbbr : true,
			callback: current_month_load
	} ),

	$month = $( '#custom-month' ).html( cal.getMonthName() ),
	$year = $( '#custom-year' ).html( cal.getYear() );
	$( '#custom-next' ).on( 'click', function() {
		cal.gotoNextMonth( updateMonthYear );
	} );
	$( '#custom-prev' ).on( 'click', function() {
		cal.gotoPreviousMonth( updateMonthYear );
	} );

	


	function updateMonthYear() {				
		$month.html( cal.getMonthName() );
		$year.html( cal.getYear() );
		/****
		from this point it is custom , for Wordjelly purpose.
		****/
		var month = cal.getMonth(),
		    year = cal.getYear(),
		    day = "01";
		var start_moment = moment(year.toString() + "-" + padDigits(month,2).toString() + "-" + day);
		var end_moment = (moment(year.toString() + "-" + padDigits(month,2).toString() + "-" + day)).endOf("month");
		get_activities(update_calendar_images_and_popups,start_moment,end_moment);
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

