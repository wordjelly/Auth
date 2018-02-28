// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function() {
  if($.fn.cloudinary_fileupload !== undefined) {
    $("input.cloudinary-fileupload[type=file]").cloudinary_fileupload();
  }
  else{
  	console.log("cloudinary is undefined");
  }
});