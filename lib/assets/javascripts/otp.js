var poll = function(resource_class_name,resource_id,intent,url_path,additional_login_param,verified,follow_url){
	var data_hash = {};
	data_hash[resource_class_name] = {
		id: resource_id,
		intent: intent
	}
	$.ajax({ 
      	data: data_hash,
      	url: url_path,
      	error: function(){
      		//errors are not handled here, because spinner.js
      		//catches any non 200/201 status and interprets it as an error
      		//thereafter directly show_error_modal is called.
      		//i could have written logic specific for otp_verification_result, by checking if it is there in the request_url, but did not do so, because otp is not always going to be in the engine, so otp should not be hardcoded anywhere.
      		//the error lands up being shown inside show_error_modal, by means of json parsing the incoming string, and showing json[:errors] as the error message.
      	}, 
      	success: function(data){
      		
	        if(counter == null){
	        	counter = 0;
	        }
	        counter++;
	        	if(verified == "true"){
	        		$("#verify_otp_result").html("Your account was successfully verified. Sign In to continue.");
	        			
	        		/***
	        		hide the additional login param block if its additional_login_param value is the same as whatever is this resource's.
	        		***/
	        		var confirmed_additional_login_param = additional_login_param;
	        		if(confirmed_additional_login_param == $("#additional_login_param_resend_block").attr("data-additional-login-param")){
	        			$("#additional_login_param_resend_block").hide();
	        		}
	        		//if this is same as whatever is showing in the data_additional_login_param of class
	        		if(follow_url){
	        			window.location = follow_url;
	        		}
	        	}
      	},
      	dataType: "script"
      });
}
