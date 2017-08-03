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
1.WHY IS THIS NOT DONE WITH SIGN_IN?
BECAUSE WITH SIGN_IN FORM WE SEND THE PARAM AS LOGIN
THAT IS THEN USED IN THE FIND_FOR_DATABASE_AUTHENTICATABLE , AS PER THE DEVISE TUTORIAL.
SO THERE WE DONT NEED TO DO THE FOLLOWING HIDDEN-FIELD-JUGGLING ETC.

2.this entire handler takes over from the trigger on the login_submit, in the you_need_to_sign_in.js.erb
and it juggles the action and the attributes as required, for the otp. 
***/
$(document).on('click','#login_submit',function(event){
    var current_screen = $('#login_title').text();
    if(current_screen == "Sign Up"){
      //WHAT WE ARE DOING HERE IS CHECKING IF THE USER IS ENTERING A MOBILE OR A EMAIL, AND IF IT IS A MOBILE, THEN WE ARE ADDING A HIDDEN FIELD CALLED ADDITIONAL_LOGIN_PARAM and sending it alongwith the rest of the form.
      var user_login = $("#" + resource_singular + "_login").val().trim();    
      var hidden_field_name = null;
      hidden_field_name = user_login.match(mobile_number_regex) ?  (resource_singular +'[additional_login_param]') : (resource_singular + '[email]'); 
      
      $(this).append('<input type="hidden" name="' + hidden_field_name + '" value="'+ user_login +'" />');
    }
    
    else if(current_screen == "Forgot Password"){
      //here i am just changing the action of the form, and the method.
      //since in case of additional_login_param, we send it to send_sms_otp + intent.
      var user_login = $("#" + resource_singular + "_email").val().trim();    
      if(user_login.match(mobile_number_regex)){
        $("#login_form").attr("action","/" + resource + "/send_sms_otp?intent=reset_password");
        $("#login_form").attr("method","GET");
      }
      else{
        $("#login_form").attr("action","/" + resource + "/password");
        $("#login_form").attr("method","POST"); 
      }
    }

    else if(current_screen == "Unlock Your Account"){
      //here i am just changing the action of the form, and the method.
      //since in case of additional_login_param, we send it to send_sms_otp + intent.
      var user_login = $("#" + resource_singular + "_email").val().trim();    
      if(user_login.match(mobile_number_regex)){
        $("#login_form").attr("action","/" + resource + "/send_sms_otp?intent=unlock_account");
        $("#login_form").attr("method","GET");
      }
      else{
        $("#login_form").attr("action","/" + resource + "/unlock");
        $("#login_form").attr("method","POST"); 
      }   
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


/***
THIS STILL NEEDS TO BE TESTED.
if this is clicked from forgot_password or unlock account, then
should also send in the intent.
***/
$(document).on('click',
  '#additional_login_param_resend_confirmation_message'
  ,function(event){
    //the resource is set in the engine's you_need_to_sign_in.js.
    //it gets set whenever we click sign_in in the nav bar.
    $.get(
    {url : "/" + resource + "/resend_sms_otp",
     data : {},
     success : function(data){},
     dataType : "script"});
});

$(document).on('click','.additional_login_param_resend_confirmation_message',function(event){
  var data_h = {};
  data_h[resource_singular] = {};
  data_h[resource_singular]["additional_login_param"] = $(this).attr("data-additional-login-param");
  $.get(
    {url : "/" + resource + "/send_sms_otp",
     data : data_h,
     success : function(data){},
     dataType : "script"});
});



