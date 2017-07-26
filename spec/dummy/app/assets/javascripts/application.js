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
//= require pollymer.min.js
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
    var current_screen = $('#login_title').text();
    if(current_screen == "Sign Up"){
      //if the title of the form is sign_up then do this.
      var user_login = $("#user_login").val().trim();    
      var hidden_field_name = null;
      hidden_field_name = user_login.match(mobile_number_regex) ? "user[additional_login_param]" : "user[email]"; 
      
      $(this).append('<input type="hidden" name="' + hidden_field_name + '" value="'+ user_login +'" />');
    }
});

/***
this function should be defined before the validation settings
and not after it.
***/
var user_login_validation_function = function(def,e,field_id){
 
  if($("#" + field_id).val().trim().match(mobile_number_regex)){
    return true;
  }
  else if($("#" + field_id).val().trim().match(email_regex)){
    return true;
  }
  return false;
}

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


//behaviour of the login_form when submitting the additional_login_parameter
//for verification.
$(document).on('click','#otp_submit',function(event){
  $("#otp_form").submit();
});

$(document).on('click',
  '#additional_login_param_resend_confirmation_message'
  ,function(event){
    //the resource is set in the engine's you_need_to_sign_in.js.
    //it gets set whenever we click sign_in in the nav bar.
    $.get(
    {url : window.location.origin + "/resend_sms_otp",
     data : {res : resource}
     success : function(data){},
     dataType : "script"});

});




