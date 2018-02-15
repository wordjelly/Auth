# Instructions for Interacting with the Auth Api

## Before You Begin

1. Follow all the instructions in [Readme.md](http://github.com/wordjelly/auth/README.md) to set up the engine in your app.
2. Download the POSTMAN chrome extension.
3. Import into the extension the JSON_API_METHODS_DUMP


## Table of Contents:

[Get An App Id and Api Key](#App_Id_And_Api_Key)  
[Emphasis](#emphasis)  


    
<a name="App_Id_And_Api_Key"/>

### Get An App Id and Api Key

The first step to use the JSON API is to get an app_id and an api_key.
You need to store these in your app, and distribute them with every copy of the app.

1.Create A  New Verified User for Yourself using steps (2) or (3) or (10) or (11), through the web application. Do the following steps using a CURL client.

2.Get the User's id using request “get a user's id by giving his token auth credentials”

3.Now make the request “Get a client given the user id”

4.Now make the request “Update the client so that it generates a app_id, doesnt use provided one”

5.Store the “current_app_id” and the “api_key”, securely in the mobile app. Use encryption or  obfuscation. Do not leave these lying around anywhere. 

