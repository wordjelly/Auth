$(document).ready(function(){

  if($.fn.cloudinary_fileupload !== undefined) {
    $("input.cloudinary-fileupload[type=file]").cloudinary_fileupload();
  	console.log("cloudinary is defined");
  }
  else{
  	console.log("cloudinary is undefined");
  }

  	if($("#signature").text() && $("#timestamp").text()){
	  	$('#upload_widget_opener').cloudinary_upload_widget(
	    { cloud_name: "doohavoda", api_key:"779116626984783", upload_signature: $("#signature").text(), upload_signature_timestamp: $("#timestamp").text(),
	    public_id: $("#public_id").text()},
		function(error, result) { console.log(error, result) });
  	}
  	else{
  		console.log("no valus");
  	}

});

