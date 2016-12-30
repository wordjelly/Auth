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
//
//= require jquery
//= require jquery_ujs
//= require underscore
//= require turbolinks
//= require materialize-sprockets
//= require main.js
//= require leanModal.js
//= require you_need_to_sign_in.js
//= require_tree .
$(document).ready(function(){
	var validation_settings = {
	  "login_form" : {
	    "user_email" : {
	      "validation_events":{
	        "focus" : true,
	        "keypress" : true,
	        "focusout": true
	      },
	      "validate_with":[
	        {"required" : "true"}
	      ]
	    }
	  }
	}

	// Initialize the validator
	try{
	var validator = new WJ_Validator(validation_settings,"materialize",false);
	}
	catch(err){
		console.log(err);
	}
});