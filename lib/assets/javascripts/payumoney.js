/***
payumoney form is autosubmitted on page load.
this happens in the show.html.erb action of the payment controller, where a hideen form with all the values prebuilt are already presented.
***/
$(document).ready(function(){
	$("#payumoney_form").submit();
});
