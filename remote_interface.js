var base_url = "http://localhost:3000/";
var sign_up_url = base_url + "users/sign_up";
var post_jmaps_url = base_url + "jmaps/create";
var auth_token_key = "authentication_token";
var es_key = "es";
var auth_details_key = "auth_details";


/****
Makes the xhr call to the requested url.
@param url[String] : target url.
@param headers[Object] : a set of key value pairs to be added as headers to the request.
@param method[String] : 'GET'/'POST' etc.
@param flag[Boolean] : the flag to pass to the xhr request.
@param post_params[Object] : set of key value pairs to be used as params in the request body of a post request.
@param get_params[Object] : set of key value pairs, to be used as params in the get url.
****/
function xhr_call(){

}



function get_user(){
    var xhr = new XMLHttpRequest();
    xhr.open("POST","http://localhost:3000/api/v1/user_info.json",true);
    add_authorization_headers(function(xhr){
        xhr.onreadystatechange = function() {
          if (xhr.readyState == 4) {
            // JSON.parse does not evaluate the attacker's scripts.
            var resp = JSON.parse(xhr.responseText);
            console.log("the remote response");
            console.log(resp);
          }
        }
        xhr.send();
    },xhr);
}


/****
Launches the chrome_web_auth_flow and gets the access token.
//expects a parameter called 
authentication_token=
****/
function launch_web_auth_flow_and_store_access_token(auth_details,fn){

        if(auth_details == null){
            redirect_url = chrome.identity.getRedirectURL();
            chrome.identity.launchWebAuthFlow(
                {'url': sign_up_url + "?redirect_url="+ redirect_url + "oauth2", 'interactive': true},
                function(redir) { 
                    
                    auth_token = $.url("?authentication_token",redir);
                    es = $.url("?es",redir);
                    set_auth_details(auth_token,es);
                    console.log("got auth details as:" );
                    console.log(auth_token);
                    console.log(es);
                    
             });
        }   
        else{
            console.log("auth details exist:" + auth_details);
        }
}

/***
adds the access token to the xhr call headers,
if the auth token is not present, adds nothing.
***/
function add_authorization_headers(fn,xhr){
    var auth_details = get_auth_details(function(auth_details){
        console.log("the auth details are");
        console.log(auth_details);
        if(auth_details != null){
            console.log("went to add the headers");
            xhr.setRequestHeader("X-User-Es",auth_details[1]);
            xhr.setRequestHeader("X-User-Token",auth_details[0]);
        }
        console.log("after adding the headers the xhr is");
        console.log(xhr);
        fn(xhr);  
    });
    
}

/***
posts the jmap as a json object to the jmaps website.
if the authorization fails, prompts the user to launch the web auth flow.
****/
function post_jmap(){

}


/***
@return : auth_token[String] - string or null.
****/
function get_auth_details(fn){
   
	chrome.storage.local.get(auth_details_key, function (result) {
         
        if(result[auth_details_key] == null){
          
        	fn(null);
        }
        else if(result[auth_details_key][auth_token_key] == null || result[auth_details_key][es_key] == null){

        }
        else{
        	fn([result[auth_details_key][auth_token_key],result[auth_details_key][es_key]]);
        }
    });
}

/****
@param: auth_token[String] - the authentication token.
@return: null.
****/
function set_auth_details(auth_token,es){
    //console.log("came to set the auth token");

	if(auth_token != null && es != null){
	    //console.log("the auth token is not null");
        obj = {};
        obj[auth_details_key] = {};
        obj[auth_details_key][auth_token_key] = auth_token;
        obj[auth_details_key][es_key] = es;
    	chrome.storage.local.set(obj, function() {
		      console.log("token set");
        });
	}
}


/****
***/