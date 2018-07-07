// the following stuff is default usually provided in any application, but is necessary for the app to work.

//= require jquery
//= require jquery_ujs
//= require underscore
//= require turbolinks
//= require cloudinary



/**
$(document).ready(function() {
    $('select').material_select();
});
***/

document.addEventListener("turbolinks:load", function() {
  $('.modal').modal();
  $('.tabs').tabs();
  $('.sidenav').sidenav();
  $('.collapsible').collapsible();
  $('.parallax').parallax();
  $('.datepicker').datepicker();
  $('select').formSelect();
});


 $(document).ready(function(){
    $('select').formSelect();
  });

$(document).ready(function(){
    $('.modal').modal();
});

$(document).ready(function(){
    $('.tabs').tabs();
  });

$(document).ready(function(){
    $('.sidenav').sidenav();
  });

$(document).ready(function(){
    $('.collapsible').collapsible();
  });

$(document).ready(function(){
    $('.parallax').parallax();
});

$(document).ready(function(){
    $('.datepicker').datepicker();
});