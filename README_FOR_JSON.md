# Instructions for Interacting with the Auth Api

## Before You Begin

1. Follow all the instructions in [Readme.md](http://github.com/wordjelly/auth/README.md) to set up the engine in your app.
2. Download the POSTMAN chrome extension.
3. Import into the extension the JSON_API_METHODS_DUMP
4. All through the following guide refer to the names in the dump of the requests.
5. The hostname for all requests is : __https://www.ourdomain.com__ (In the JSON DUMP the hostname used is localhost:3000)


## Id's and other details generated / used while buildling this tutorial 

1. App developer user id: 5a857ed5421aa919635263fc
"current_app_id" : "5a85ae25e138231aa93495e3",
"api_key" : "3a7d6c8b4fe2b8c0c652666ef07362b39a7bc013f64d53437230549cc9cddda5"
4. Client Id: 5a857eec421aa919635263fe


## Specific Prerequisites for Android App
   
1. With every request pass the header "OS-ANDROID"


## Specific Prerequisites for for Iphone App

1. With every request pass the header "OS-IOS"


## Table of Contents:

### [1. Get An App Id and Api Key](#App_Id_And_Api_Key)  
### [2. Create A User With A Mobile Number](#Create_User_With_Mobile_Number)
### [2a. User requests Resend Confirmation Otp](#Resend_Confirmation_Otp)
### [2b. User Submits OTP](#User_Submit_Otp)
### [2c. User Polls Verification Status](#Poll_Verification_Status)
### [2d. Sign In A User with Mobile and Password](#Sign_In_With_Mobile_And_Password)
### [3. Create A User with Email and Password](Create_User_With_Email)
    
<a name="App_Id_And_Api_Key"/>

### 1.Get An App Id and Api Key

The first step to use the JSON API is to get an app_id and an api_key.
You need to store these in your app, and distribute them with every copy of the app.

1.Create A  New Verified User for Yourself using steps (2) or (3) or (10) or (11), through the web application. 

2.Still in the web application, click on "Profile" in the top right navigation bar. Now in the url in the address bar the user id will be seen after : /profiles/{user_id}. Copy that user_id.

** Do the following steps through any CURL client.

3.Now make the request “Get a client given the user id”. 

4.Now make the request “Update the client so that it generates a app_id, doesnt use provided one”, using the id of the user, in the put request, as the id.

5.Repeat step 3.

6.Store the “current_app_id” and the “api_key”, securely in the mobile app. Use encryption or  obfuscation. Do not leave these lying around anywhere. 


<a name="Create_User_With_Mobile_Number"/>

### 2.Create A User With A Mobile Number

1. Use the current_app_id and api_key that was got in (1)
2. Make the request __"create a user with mobile and password"__

3. Expect the response code to be 200, any other response code is to be termed as an error.

4. If there are validation errors, these will appear in the response as:

```
{
    "errors": "recaptcha validation error"
}

## or

{
    "nothing": true,
    "errors": [
        "Additional login param is already taken"
    ]
}
```

5. If there is any other error, tell the user to try again later.

6. If the response code is 201 -> proceed.



<a name="Resend_Confirmation_Otp" />

### 2a.User requests Resend Confirmation Otp

1. Peform the request "Resend an sms otp to a mobile number, for confirming account"

2. If the response code is 200, all is well. Otherwise you can render the errors from the response. They will appear similar to the errors in point (2)


<a name="User_Submit_Otp" />

### 2b.User Submits Otp

1. Perform the request "Submit the otp received by user to the server"

2. If the response is 200, show the message "now verifying your otp" and proceed to the next step.

3. If the response is something other than 200, then show the user the option -> 1) retry 2) resend otp


<a name="Poll_Verification_Status" />

### 2c. User Polls for Otp Verification Status

1. Perform the request "Check if otp is correct for purpose of confirming account"

2. If the verification fails you will get a message like this:

```
{
    "intent_verification_message": null,
    "errors": [
        "Additional login param Either otp or additional login param is incorrect, try resend otp"
    ],
    "resource": {
        "nothing": true
    },
    "verified": false
}
```

3. If the verification is pending, there will be no errors, but verified will stil be false, in that case, poll this endpoint again after 15 seconds.

4. If the verification status is true, then show a message saying your account is now confirmed.


<a href="Sign_In_With_Mobile_And_Password" />

### 2d. Sign In With Mobile And Password

1. Use the Request ""

2. If the authentication is successfull you will get a response like:

```
{
    "authentication_token": "1gA3HxhoxacS2y_6wbzs",
    "es": "0d546dbd86d36c54acedfb15f4938b8e516d8c8b353513466a32ab49a9afaa5b"
}
```
And response code of 201.

3. If the authentication fails, you will get a 401.


```
{
    "success": false,
    "errors": [
        "u shall not pass LOL"
    ]
}

```


4. If the response is anything other than success, then show the option for "Forgot Password".

5. Store the __authentication_token__ and the __es__ locally. It is to be used for all requests as authentication, wherever indicated.

6. The __authentication_token__ will expire every 2 days. When that happens, all requests that you issue with using the token will fail with a 401. If you ever hit a 401 while using the authentication_token and es, redirect the user to sign-in with his email/mobile and password -> get the refreshed authentication_token and es and store it and use it thereafter.


<a href="Create_User_With_Email" />

### 3.Create A User with Email and Password

1. Issue the request ""