// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
jQuery(function() {
  return $.ajax({
    url: 'https://apis.google.com/js/client:plus.js?onload=gpAsyncInit',
    dataType: 'script',
    cache: true
  });
});

window.gpAsyncInit = function() {
  gapi.auth.authorize({
    immediate: true,
    response_type: 'code',
    cookie_policy: 'single_host_origin',
    client_id: '79069425775-njseh8c39qsf24bicherbd3hdvk5o21c.apps.googleusercontent.com',
    scope: 'email profile'
  }, function(response) {
    return;
  });
  $('.googleplus-login').click(function(e) {
    e.preventDefault();
    gapi.auth.authorize({
      immediate: false,
      response_type: 'code',
      cookie_policy: 'single_host_origin',
      client_id: '79069425775-njseh8c39qsf24bicherbd3hdvk5o21c.apps.googleusercontent.com',
      scope: 'email profile'
    }, function(response) {
      if (response && !response.error) {
      	console.log("this is the response");
      	console.log(response);
      	delete response['g-oauth-window'];

        // google authentication succeed, now post data to server.
        jQuery.ajax({type: 'POST', url: "/authenticate/omniauth/google_oauth2/callback", 
		  data: response,
          success: function(data) {
            // response from server
            console.log("the success response is:");
            console.log(data);
          }
        });
      } else {
      	console.log("google authentication failed");
        // google authentication failed
      }
    });
  });
};