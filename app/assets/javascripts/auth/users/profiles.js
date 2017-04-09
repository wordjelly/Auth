// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).on("click","#get_activities",function(event){
	var now = moment();
	var now_start = now.unix();
	var startDate = now.startOf("month");
	$.get( "/activities/get_activities",
	 	 { user_id: $("#user_data").data("resource").id, range: {from: startDate.unix(), to: now_start} , only:["image_url"]},
	 	 function(data){
	 	 	console.log("response got");
	 	 	console.log(data);
	 	 },
	 	 "json"
	 	 );
	
});


