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



Content-Type:application/json
X-User-Token:3j79sRhhc3bajDX7Q4Wm
X-User-Aid:5a85ae25e138231aa93495e3
X-User-Es:7c151a22631cfcdd4517b2f44043df2d46be0e3411ff0500170ed95a64a2e27f

User Id: 5a86c78c421aa92e0a8afeca






## Specific Prerequisites for Android App
   
1. With every request pass the header "OS-ANDROID"


## Specific Prerequisites for for Iphone App

1. With every request pass the header "OS-IOS"


## Table of Contents:
### [Flows for Sign-In, Sign-Up](#SignIn_Flows)
### [1. Get An App Id and Api Key](#App_Id_And_Api_Key)  
### [2. Create A User With A Mobile Number](#Create_User_With_Mobile_Number)
### [2a. User requests Resend Confirmation Otp](#Resend_Confirmation_Otp)
### [2b. User Submits OTP](#User_Submit_Otp)
### [2c. User Polls Verification Status](#Poll_Verification_Status)
### [2d. Sign In A User with Mobile and Password](#Sign_In_With_Mobile_And_Password)
### [3. Update A User's Mobile Number](Update_User_Mobile)
### [4. Get A User's Id](Get_User_Id)
### [5. Create A User With Email](Create_User_Email)
### [6. Request Resend Confirmation Email](Request_Resend_Confirmation_Email)
### [7. Add A Mobile Number to Account With Email](Add_Mobile_To_Email)
### [8. Change The Email](Change_Email)
### [9. Request Forgot Password Instructions Using Mobile](Forgot_Password_With_Mobile)
### [10. Request Unlock Account with Mobile](Unlock_Account_With_Mobile)
### [11. Request Forgot Password Instructions with Email](Forgot_Password_With_Email)
### [12. Request Unlock Account With Email](Unlock_Account_With_Email)
### [13. Change the Password](Change_User_Password)
### [14. Sign In Using Google OAuth2](Google_OAuth)
### [15. Sign In Using Facebook OAuth2](Facebook_OAuth)

<a name="SignIn_Flows" /a>

### Flows for Sign-In, Sign-Up

TODO

    
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

2a. If you are making the Android App, you must add the response of verifying the recaptcha into the "g-recaptcha-response" key. In the POSTMAN JSON DUMP that value is currently left blank. 

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


<a href="Update_User_Mobile" />

### 3.Update A User's Mobile Number

1. First Get the User's Id, by doing point (4).
2. Now issue the request "Update User With Mobile"
You will get a response like:
{
    "nothing": true
}
Response code will be: 200
If any other response code : say try after sometime.
If any validation errors, then show them.
If not authenticated, get the user to sign in again, and then try again with new auth_token and es.

3. If all is successfull, follow the flow to Verify Otp as above.

4. After the OTP has been successfully verified, go and sign in the user again , because the auth token changes whenever the email/mobile/password is changed.

<a href="Get_User_Id" />

### 4. Get A User's Id

1. Make the Request "get a user's id by giving his token auth credentials".
2. You will get a response like:

{
    "authentication_token": "1gA3HxhoxacS2y_6wbzs",
    "es": "0d546dbd86d36c54acedfb15f4938b8e516d8c8b353513466a32ab49a9afaa5b",
    "id": "5a85b715421aa91ffc68c86f",
    "admin": "false"
}
Response code will be: 200 ok.

2a. If the credentials are invalid, you will get code 401, in that case, go and make the user sign in again, with his username and password and then get the refreshed auth_token and es, and try again.
2b. If the response code is something else, tell the user to try again after sometime.

3. Store the User Id locally.


<a href="Create_User_Email" /a>

### 5. Create A User With Email

1. Make the request : "Create User with email and password"

Response Code : 200
Response Body :
{
	"nothing" : "true"
}

Any other response code -> say try later
Any validation error -> show the error.


<a href="Request_Resend_Confirmation_Email" /a>

### 6. Request Resend Confirmation Email 

1. Make the request: "Request Resend Confirmation Email"

2. Expected Response code : 201

3. Expected Response Body : {}

4. If any validation errors, then show them.

5. If any other erorr,say try later.


<a href="Add_Mobile_To_Email" /a>

### 7. Add A Mobile Number to Account With Email

1. Make the request : ""

2. Response Code : 200

3. Response Body : 

{
    "authentication_token": "m3GB1uw1byh9QGibqhu-",
    "es": "d8b05d593e4612f4d063cd52d9096ac6100611f4a64183d00019941b3a2662de"
}

Note the authentication token changes on adding the mobile. This is because there is still one confirmed authentication key, i.e the email. 

4. Show any validation errors

5. Any other error, try later.

6. Now proceed to verify the otp as before.


<a href="Change_Email" /a>

### 8. Change The Email

1. Make Request To : Update user's email

2. Expected Response Code : 200

3. Expected Response Body : 

{
    "authentication_token": "M_RjjjCxs8ps8TdYsx8t",
    "es": "d8b05d593e4612f4d063cd52d9096ac6100611f4a64183d00019941b3a2662de"
}

4. Note that the authentication token changes again , because the mobile is confirmed.

5. Show any validation errors

6. Any other error, try later.


<a href="Forgot_Password_With_Mobile" /a>

### 9. Request Forgot Password Instructions Using Mobile 

1. This is only possible if the user has a confirmed email account.

2. If the user does not have a confirmed email account, tell him that he can't do this, or don't show the option at all.

3. Make A Request to :

"Submit a reset_password request using a mobile number"

4. Expected Code : 200, Expected Response :
{
"nothing" : true
}

5. Now do step : 2b

6. Now make request to  "Check if otp is correct, for purpose of reset password"

7. Expected Response Code : 200

8. Expected Response Body: 

```
{
    "intent_verification_message": "An email has been sent to your email account, with instructions on resetting your password",
    "errors": [],
    "resource": {
        "nothing": true
    },
    "verified": true
}
```

9. Any other errors, or validation errors, to be handled as usual.


<a href="Unlock_Account_With_Mobile" /a>

### 10. Request Unlock Account with Mobile:

1. This is only possible if the user has a confirmed email account.

2. If the user does not have a confirmed email account, tell him that he can't do this, or don't show the option at all.

3. Make A Request to :

"Submit a unlock_account request using a mobile number"

4. Expected Code : 200, Expected Response :
{
"nothing" : true
}

5. Now do step : 2b

6. Now make request to  "Check if otp is correct, for purpose of unlock account"

7. Expected Response Code : 200

8. Expected Response Body: 

```
{
    "intent_verification_message": "An email has been sent to your email account, with instructions on unlocking your account",
    "errors": [],
    "resource": {
        "nothing": true
    },
    "verified": true
}
```

9. Any other errors, or validation errors, to be handled as usual.


<a href="Forgot_Password_With_Email" /a>

### 11. Request Forgot Password Instructions with Email

1. Make The Request "Submit a Reset Password Request with Email"

2. Response code expected : 201

3. Response expected : {}

4. Follow usual instructions for validation errors / other errors.


<a href="Unlock_Account_With_Email" /a>

### 12. Request Unlock Account With Email

1. Make the request "Submit An Unlock Account Request With Email".

2.Response Code expected : 201

3.Response Expected : {}

4.Validation Errors look like: 

```
{
    "errors": {
        "email": [
            "was not locked"
        ]
    }
}
```

5. Handle errors as usual.


<a href="Change_User_Password" /a>

### 13. Change the Password

1. Make the Request "Update the User's Password"

2. Expected Response code : 200 

3. Expected Response : 

```
{
    "authentication_token": "sMy6tVJczEs17vNy7V21",
    "es": "d8b05d593e4612f4d063cd52d9096ac6100611f4a64183d00019941b3a2662de"
}
```

4. Note that the authentication token changes whenever you change the password.

5. Handle errors as usual



<a href="Google_OAuth" /a>

### 14. Sign In Using Google OAuth2

1. There are two possibilities for doing a google oauth2 sign in .

2. From the app you can request : 

a. "Sign In With Google Oauth 2 and Id Token" - if you request an id token for google oauth.
b. "Sign In With Google Oauth 2 and Access Token" - if you request access token with google oauth.

3. Whichever one you request , expected response code : 201

4. Expected Response:

{
    "authentication_token": "uy-jf453dobNoCpaCzB8",
    "es": "7bed7eea649cbe1962e672acd44d93ac7ab88d91752b94e7a309f9d4d12eb67e"
}

5. In case of failure :

Response Code : 500

Response :

{
    "failure_message": null
}

6. Handle 401, as usual.

7. Any other error handle as usual.

<a href="Facebook_OAuth" /a>

### 15. Sign In Using Facebook OAuth2

1. First do the facebook oauth flow in the app.

2. Make the request to : Sign In With Facebook Oauth2 fb_exchange_token

3. Expected Response code : 201

4. Expected Response:

{
    "authentication_token": "uy-jf453dobNoCpaCzB8",
    "es": "7bed7eea649cbe1962e672acd44d93ac7ab88d91752b94e7a309f9d4d12eb67e"
}

5. In case of failure :

Response Code : 500

Response :

{
    "failure_message": null
}

6. Handle 401, as usual.

7. Any other error handle as usual.
