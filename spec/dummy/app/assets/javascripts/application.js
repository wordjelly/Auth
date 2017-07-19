// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.

//= require jquery
//= require jquery_ujs
//= require_tree .


/////THIS CODE SHOWS HOW TO OVERRIDE ALL THE CLIENT SIDE CODE NEEDED
/////FOR VALIDATIONS TO WORK FOR THE SIGN_IN_FORM.
var mobile_number_regex = /^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/;
var email_regex = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[A-Z]{2}|com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum)\b/;
/***
takes the value of the user_login field
trims it
then matches it with the mobile number regex
if it matches, then makes the hidden field user[mobile]
if it doesnt match, then makes the hidden field user[email]
then returns true.
***/
$(document).on('submit','#login_form',function(event){
	var user_login = $("#user_login").val().trim();
	var hidden_field_name = null;
	hidden_field_name = user_login.match(mobile_number_regex) ? "user[additional_login_param]" : "user[email]"; 
	$(this).append('<input type="hidden" name="' + hidden_field_name + '" value="'+ user_login +'" />');
	return true;
});


//the user login validation function is included in you_need_to_sign_in.js
var validation_settings = {
  "login_form" : {
    "user_login" : {
      "validation_events":{
        "keyup" : true
      },
      "validate_with":[
        {"required" : "true",
         "failure_message": "this field is required"
    	},
    	{"format" : user_login_validation_function,
    	 "failure_message": "Please enter a valid email or mobile number"
    	}
      ]
    },
    "user_password":{
    	"validation_events":{
    	  "keyup":true
    	},
    	"validate_with":[
      	{"required" : "true",
      	 "failure_message": "this field is required"
      	}
      ]
    }
  }
}


var user_login_validation_function = function(def,e,field_id){
  
  if($("#" + field_id).val().trim().match(mobile_number_regex)){
  	return true;
  }
  else if($("#" + field_id).val().trim().match(email_regex)){
  	return true;
  }
  return false;
}




