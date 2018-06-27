var generateSignature = function(callback, params_to_sign){
	params_to_sign["_id"] = $("#image_id").text();
	params_to_sign["parent_id"] = $("#parent_id").text();
	params_to_sign["parent_class"] = $("#parent_class").text();
    $.ajax({
     	url     : "/auth/images",
     	type    : "POST",
     	dataType: "text",
     	data    : { image: params_to_sign
     			  },
     	complete: function() {console.log("complete")},
     	success : function(signature, textStatus, xhr) {
     	 console.log("signature returned is:");
     	 console.log(signature);
     	 callback(signature); },
     	error   : function(xhr, status, error) { console.log(xhr, status, error); }
    });
}


document.addEventListener("turbolinks:load", function() {
  $('#upload_widget_opener').cloudinary_upload_widget(
  { cloud_name: "doohavoda", api_key:"393369625566631", upload_signature: generateSignature,
  public_id: $("#image_id").text()},
  function(error, result) { console.log(error, result) });
})