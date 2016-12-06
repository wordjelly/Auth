 $(document).bind("ajaxSend", function(){
   $(".modal:visible").find(".error_notification").hide();
   //$("body").remove("#dog");
   $("#progress_circle").show();
 }).bind("ajaxStop", function(){
   $("#progress_circle").hide();
 }).bind("ajaxComplete",function(){
   //$("body").append("<div id='dog'>dogged</div>");
 }).bind("ajaxError",function(event,request,settings){
   $("#progress_circle").hide();
   var request_url = settings.url;
   var request_method = settings.type;
   var status = request.status;
   var error = request.responseText;
   var readyState = request.readyState;
   //console.log("url:" + request_url);
   //console.log("method:" + request_method);
   //console.log("status:" + status);
   //console.log("error:" + error);
   //console.log("readyState:" + readyState);
   //this handles the request abort that occurs as a normal part of the
   //remotipart request.
   if(status == 0 && readyState == 0 && request.statusText == "canceled"){
      return;
   }

   if(status == 200 || status == 201 || status == 302){
      return;
   }
   
   if(request_url.endsWith("sign_in") && request_method == "POST" && status == 401){
      error_message = error;
      mark_invalid_fields_on_sign_in_failure(error);
   }
   show_modal_error_message(error);
 });

 var toggle_ajax_error_modal = function(){
 	//console.log("came to toggle ajax error modal");
   if($("#ajax_error_modal").is(":visible")){

 	}
 	else{
 		$("#ajax_error_modal").openModal();
 	}
 }

 var set_ajax_error_modal = function(){
	//on clearing the 
	$("#ajax_error_modal").leanModal({
		dismissible: true, 
	    opacity: .5, 
		in_duration: 300, 
		out_duration: 200,
		after_close: function(options){

		}
	});

}

$(document).ready(set_ajax_error_modal);
$(document).on('page:load', set_ajax_error_modal);
;