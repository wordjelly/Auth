# Instructions for Interacting with the Auth Api

## Before You Begin


1. Download the POSTMAN chrome extension.
2. Import into the extension the json request dump.
3. All through the following guide refer to the names in the dump of the requests.
4. The hostname for all requests is : __https://www.ourdomain.com__ (In the JSON DUMP the hostname used is localhost:3000)


## Id's and other details generated / used while buildling this tutorial 

1. App developer user id: 
"current_app_id" : "5a85ae25e138231aa93495e3",
"api_key" : "3a7d6c8b4fe2b8c0c652666ef07362b39a7bc013f64d53437230549cc9cddda5"
4. Client Id: 5a857eec421aa919635263fe
-------------------------------------------------------------

ADMIN USER
----------

Content-Type:application/json
X-User-Token:wYHQ_6rqxH_QUvQ3mVE6
X-User-Aid:5a85ae25e138231aa93495e3
X-User-Es:5bd25e82b431847b39660ee92b78bda6405faac47cba47b7b5d98693781e00d2

User Id: 5a870959421aa90f36a35558
E-Mail : anyone@gmail.com
password : password
--------------------------------------------------------------

OTHER USER
----------

Content-Type:application/json
X-User-Token:AicEbTzVxuiu8SYq47LQ
X-User-Aid:5a85ae25e138231aa93495e3
X-User-Es:ca4685bfcc90b9a1cb13ae92919b0e9acf751f5ce0365a87c5c64270ee8a97a3


User Id: 5a87111b421aa91047c428b9
mobile : 9999999999
E-Mail : none
password: password


--------------------------------------------------------------

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

### [16. Set A User As Admin](Set_User_As_Admin)
### [17. Admin Creates User With Mobile](Admin_Creates_User_With_Mobile)
### [18. Admin Creates User With Email](Admin_Creates_User_With_Email)
### [19. Admin Resends Confirmation Email For User](Admin_Resends_Confirmation_Email)
### [20. Admin Resends Confirmation Otp For User](Admin_Resends_Otp)
### [20a. Admin Resends the Reset Password Link to the User](Resend_Reset_Password_link)
### [21. Searching for A String at Search Endpoint For Authenticated User](Search_Authenticated)

### [22. Creating A Product](Create_Product)
### [23. Viewing A Product](View_Product)
### [24. Updating A Product](Update_Product)
### [25. Destroy A Product](Destroy_Product)
### [26. View All Products](View_All_Products)
### [27. Create A Cart Item](Create_Cart_Item)
### [28. View A Cart Item](View_Cart_Item)
### [29. Update A Cart Item](Update_Cart_Item)
### [30. Destroy A Cart Item](Destroy_Cart_Item)
### [31. View WishList](View_WishList)
### [32. Add Item To WishList](Add_Item_to_WishList)
### [33. Remove Item From WishList](Remove_Item_From_WishList)


### [34. Create An Empty Cart](Create_Cart)
### [34a. Create A Cart With Cart Items](Create_Cart_With_Items)
### [35. Add_Items_to_Cart](Add_Items_To_Cart)
### [36. Remove_Items_From_Cart](Remove_Items_From_Cart)
### [37. View Cart](View_Cart)
### [38. View All Carts](View_All_Carts)


### [39. Make Cash Payment To Cart](Make_Cash_Payment)
### [40. Approve Cash Payment As Admin](Approve_Cash_Payment)
### [41. Make Card Payment To Cart](Make_Card_Payment)
### [42. Approve Card Payment As Admin](Approve_Card_Payment)
### [43. Make Cheque Payment To Cart](Make_Cheque_Payment)
### [44. Approve Cheque Payment As Admin](Approve_Cheque_Payment)
### [45. Disapprove an Approved Payment](Disapprove_Payment)
### [46. Cancel A Cart Item As Admin, After Payment Has been Made](Cancel_Cart_item_As_Admin)
### [47. Make Refund Request](Make_Refund_Request)
### [48. Approve Refund Request As Admin](Approve_Refund_Request)
### [49. Refresh Cart Item](Refresh_Cart_Item)
### [50. Create A Gateway Payment](Create_Gateway_Payment)
### [51. Verify Gateway Payment](Verify_Gateway_Payment)
### [51a. Get Payment Receipt](Get_Payment_Receipt)
### [52. Create A Discount Coupon From A Cart](Create_Discont_Coupon_From_Cart)
### [53. View A Discount Coupon](View_Discount_Coupon)
### [54. Create Cart From Discount Coupon](Create_Cart_From Discount_Coupon)
### [55. Make Payment Into Cart Using Discount Coupon](Make_Payment_To_Cart_Using_Discount_Coupon)
### [56. Verify_Discount_Coupon_Request](Verify_Discount_Coupon_Request)
### [57. Decline Discount Coupon Request](Decline_Discount_Coupon_Request)
### [58. Use the Approved Discount Coupon](Use_Approved_Discount_Coupon)
### [59. Create Cartless Discount Coupon](Create_Cartless_Discount_Coupon)
### [60. Use Cartless Discount Coupon](Use_Cartless_Discount_Coupon)


<a name="SignIn_Flows" /a>

### Flows for Sign-In, Sign-Up

TODO

    
<a name="App_Id_And_Api_Key"/>

### 1.Get An App Id and Api Key

The first step to use the JSON API is to get an app_id and an api_key.
You need to store these in your app, and distribute them with every copy of the app.

1.Create A  New Verified User for Yourself using steps (2) or (3) or (10) or (11), through the web application. 

2.Still in the web application, click on "Profile" in the top right navigation bar. Now in the url in the address bar the user id will be seen after : /profiles/{user_id}. Copy that user_id.

3. Now visit the url /clients/{user_id}
4. There click Edit
5. There add any valid url of the type : www.google.com, don't use http or https, and add anything into the appid
6. Now click update
7. You will get to see your app_id and api_key on the next page.
8. Copy and Store that for future use.

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

6. If the response code is 201> proceed.



<a name="Resend_Confirmation_Otp" />

### 2a.User requests Resend Confirmation Otp

1. Peform the request "Resend an sms otp to a mobile number, for confirming account"

2. If the response code is 200, all is well. Otherwise you can render the errors from the response. They will appear similar to the errors in point (2)


<a name="User_Submit_Otp" />

### 2b.User Submits Otp

1. Perform the request "Submit the otp received by user to the server"

2. If the response is 200, show the message "now verifying your otp" and proceed to the next step.

3. If the response is something other than 200, then show the user the option> 1) retry 2) resend otp



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

6. The __authentication_token__ will expire every 2 days. When that happens, all requests that you issue with using the token will fail with a 401. If you ever hit a 401 while using the authentication_token and es, redirect the user to sign-in with his email/mobile and password> get the refreshed authentication_token and es and store it and use it thereafter.


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

Any other response code> say try later
Any validation error> show the error.


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

a. "Sign In With Google Oauth 2 and Id Token" if you request an id token for google oauth.
b. "Sign In With Google Oauth 2 and Access Token" if you request access token with google oauth.

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


<a href="Set_User_As_Admin" /a>

### 16. Set A User As Admin

1. To do this the user executing the request has to be an admin user.
2. Get the User who you want to make admin by searching for it.
3. From the response get the id.
4. Make the Request "Update User Profile"
5. While making this request, pass the headers (Auth Token, es and app id) of the admin user.
6. In the request body , pass the "id" of the user who you searched for above.
7. Expected Response Code : 204
8. Expected Response Body : null
9. Handle any other errors, as usual.
10. Call the get user id endpoint after this to check if the admin has been set to true.


<a href="Admin_Creates_User_With_Mobile" /a>

### 17. Admin Creates User With Mobile

1. Make the request "Admin creates user with mobile and password"

2. Headers : Provide the Auth token and es of the admin user.

3. Provide the additional_login_param as the mobile number of the user who the admin wants to create.

4. Exepcted Response Code : 201

5. Expected Response :

{
 "nothing" : true
}

6. Any validation errors, to be handled as usual

7. Any other error to be handled as usual.

8. Now do request (2b)

8a. Now do request (2c)> and it will tell that the user is confirmed.

9. At the end>  tell the admin, that the user should have got an sms with reset password instructions.



<a href="Admin_Creates_User_With_Email" /a>

### 18. Admin Creates User With Email:

1. Make the Request : "Admin creates user with email and password"

2. Expected Response Code: 201

3. Exepcted Response: 

```
{
    "nothing" : true
}
```

4. This should result in a confirmation email being sent to the user.

5. If the user doesnt receive the confirmation email, then follow (19)



<a href="Admin_Resends_Confirmation_Email" /a>

### 19. Admin Resends Confirmation Email for User:

1. Follow point (6)


<a href="Admin_Resends_Otp" /a>

### 20. Admin Resends Confirmation Otp For User

1. Just follow request (2a)> with the mobile number of the user


<a href="Resend_Reset_Password_link" /a>

### 20a. Admin Resends the Reset Password Link to the User

1. Make the request : Resend the Reset Password Link to the User created by Admin
2. Expected Response Code : 204
3. Expected Response : null
4. Handle validation and other errors as usual.




<a href="Search_Authenticated" /a>

### 21. Searching for A String at Search Endpoint For Authenticated User

1. Make Request : Search Authenticated

2. Expected Response Code : 200

3. Expected Response :

Array Of Json Objects, each object will have for sure the key _type, you can use that to instantiate views in your app depending on the model.

[
    {
        _type : "Model Name"
    }
]

-------------------------------------------------------------

<a href="Create_Product" /a>

### 22. Creating A Product


N.B : Product can only be created by an admin user.

1. Make A Request to  : "Create A Product"

2. Expected Response Code : 201

3. Expected Response : JSON Representation of Product Object

```
{
    "_id": {
        "$oid": "5a88618a421aa916385a3b45"
    },
    "brand": "Ford",
    "category": "Cars",
    "created_at": "2018-02-17T17:08:26.373Z",
    "name": "Ford Ecosport",
    "price": "120000.0",
    "public": "yes",
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-17T17:08:26.373Z"
}
```

4. Handle not authenticated, or validation errors as usual.


<a href="View_Product" /a>

N.B : product can be viewed by anyone including non-authenticated users.

### 23. Viewing A Product

1. Make the Request "Get A Particular Product"

2. Expected Response Code : 200

3. Expected Response : As in (22)


<a href="Update_Product" /a>

N.B : product can only be updated by admin user.

### 24. Updating A Product

1. Make the Request "Update A Product".

2. Expected Response Code : 204

3. Expected Response Body : null



### [25. Destroy A Product](Destroy_Product)

N.B : product can only be deleted by admin user.

1. Make the request : "Delete a Product"

2. Expected Response Code : 204

3. Expected Response Body : null


### [26. View All Products](View_All_Products)

1. Make the Request "Get All Products"

2. Expected Response Code : 200

3. Expected Response : 

```
[
    {product_as_json},
    {product_as_json}
]
```


<a href="Create_Cart_Item" /a>

### 27. Create A Cart Item

N.B Only signed in user can create a cart item.

1. Make Request to "Create Cart Item"
2. Expected Response Code : 201
3. Expected Response Body :  (JSON Representation of Object)

```
{
    "_id": {
        "$oid": "5a8870e5421aa916385a3b49"
    },
    "accept_order_at_percentage_of_price": 1,
    "accepted": null,
    "accepted_by_payment_id": null,
    "created_at": "2018-02-17T18:13:57.855Z",
    "discount": null,
    "discount_code": null,
    "name": "Ford Ecosport",
    "parent_id": null,
    "price": "120000.0",
    "product_id": "5a88618a421aa916385a3b45",
    "public": "no",
    "quantity": 1,
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-17T18:13:57.855Z"
}
```



### [28. View A Cart Item](View_Cart_Item)

N.B : Only user who created the cart item or admin can view the cart item.

1. Make the Request : "Get A Particular Cart Item."
2. Expected Response Code : 200
3. Expected Response : Same as in 27



### [29. Update A Cart Item](Update_Cart_Item)

N.B : Only user who created the cart item or admin can update the cart item.

1. Make the request : Update Cart Item.
2. Expected Response Code 204
3. Expected Response Body : null


### [30. Destroy A Cart Item](Destroy_Cart_Item)

N.B : Only user who created the cart item or admin can update the cart item.

1. Make the Request "Delete A Cart Item"

2. Expected Response Code : 204.

3. Expected Response Body: null





### [31. View WishList](View_WishList)

N.B : WishList is all the cart_items which do not have a cart_id on them.

1. Make the Request "Get all cart items in the wish list"
2. Expected Response Code : 204
3. Expected Response Body : 


```
[
    {cart_item_as_json},
    {cart_item_as_json}
]
```

<a href="Add_Item_to_WishList" /a>

### 32. Add Item To WishList

1. Make Request 27.


<a href="Remove_Item_From_WishList" /a>

### [33. Remove Item From WishList]

2. Make Request 30.


<a href="Create_Cart" /a>

### [34. Create An Empty Cart]

1. Make Request "Create An Empty Cart"
2. Expected Response : 201 Created
3. Expected Response Body: 

```
{
    "_id": {
        "$oid": "5a886e15421aa916385a3b47"
    },
    "created_at": "2018-02-17T18:01:57.063Z",
    "discount_id": null,
    "name": null,
    "notes": null,
    "public": "no",
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-17T18:01:57.063Z",
    "cart_items": [],
    "cart_payments": [],
    "cart_price": 0,
    "cart_paid_amount": 0,
    "cart_pending_balance": 0,
    "cart_credit": 0,
    "cart_minimum_payable_amount": null
}

OR

{
    "_id": {
        "$oid": "5a88a101421aa93e59e4addb"
    },
    "accept_order_at_percentage_of_price": 1,
    "accepted": null,
    "accepted_by_payment_id": null,
    "created_at": "2018-02-17T21:39:13.283Z",
    "discount": null,
    "discount_code": null,
    "name": "Ford Ecosport",
    "parent_id": null,
    "price": "120000.0",
    "product_id": "5a88618a421aa916385a3b45",
    "public": "no",
    "quantity": 1,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-17T21:39:13.283Z"
}
```

<a href="Create_Cart_With_Items" /a>

### 34a. Create A Cart With Cart Items

1. Make Request "Create A Cart With Cart Items."

2. Response Code : 201

3. Body Same as for (34)


<a href="Add_Items_To_Cart" /a>

### [35. Add_Items_to_Cart]

1. Make the Request "Add Cart Items to Cart"
2. Expected Response Code : 204
3. Expected Response Body : null



<a href="Remove_Items_From_Cart" /a>

### [36. Remove_Items_From_Cart]

1. Make the Request "Remove Cart Items From Cart"
2. Expected Response Code : 204
3. Expected Response Body : null


<a href="View_Cart" /a>

### [37. View Cart]

1. Make the Request "Get A Cart"
2. Expected Response Code : 200
3. Expected Response 

```
{
    "_id": {
        "$oid": "5a886e15421aa916385a3b47"
    },
    "created_at": "2018-02-17T18:01:57.063Z",
    "discount_id": null,
    "name": null,
    "notes": null,
    "public": "no",
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-17T18:01:57.063Z",
    "cart_items": [
        {
            "_id": {
                "$oid": "5a8870e5421aa916385a3b49"
            },
            "accept_order_at_percentage_of_price": 1,
            "accepted": null,
            "accepted_by_payment_id": null,
            "created_at": "2018-02-17T18:13:57.855Z",
            "discount": null,
            "discount_code": null,
            "name": "Ford Ecosport",
            "parent_id": "5a886e15421aa916385a3b47",
            "price": "120000.0",
            "product_id": "5a88618a421aa916385a3b45",
            "public": "no",
            "quantity": 1,
            "resource_class": "User",
            "resource_id": "5a870959421aa90f36a35558",
            "updated_at": "2018-02-17T18:15:15.339Z"
        }
    ],
    "cart_payments": [],
    "cart_price": "120000.0",
    "cart_paid_amount": 0,
    "cart_pending_balance": "120000.0",
    "cart_credit": 0,
    "cart_minimum_payable_amount": "120000.0"
}
```

<a href="View_All_Carts" /a>

### [38. View All Carts]

1. Make the Request : "Get All Carts"
2. Response Code : 200
3. Response Body : 

```
[
    {
        "_id": {
            "$oid": "5a886e15421aa916385a3b47"
        },
        "created_at": "2018-02-17T18:01:57.063Z",
        "discount_id": null,
        "name": null,
        "notes": null,
        "public": "no",
        "resource_class": "User",
        "resource_id": "5a870959421aa90f36a35558",
        "updated_at": "2018-02-17T18:01:57.063Z",
        "cart_items": null,
        "cart_payments": null,
        "cart_price": null,
        "cart_paid_amount": null,
        "cart_pending_balance": null,
        "cart_credit": null,
        "cart_minimum_payable_amount": null
    }
]
```

N.B: the cart information of each cart like cart_price, items, etc is not returned in this request.


<a href="Make_Cash_Payment" /a>

### [39. Make Cash Payment To Cart]

1. First do request 37.
2. See the cart_pending_balance.
3. Now make the request "Create A Cash Payment" with the amount = cart_pending_balance
4. Expected Response code : 201
5. Expected Response Body : 

```
{
    "_id": {
        "$oid": "5a8881a0421aa916385a3b4a"
    },
    "amount": 120000,
    "cart_id": "5a886e15421aa916385a3b47",
    "cash_change": 0,
    "created_at": "2018-02-17T19:25:20.889Z",
    "discount_id": null,
    "gateway_callback_called": false,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "cash",
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-17T19:25:20.889Z",
    "payment_receipt": null
}
```

<a href="Approve_Cash_Payment" /a>

### 40. Approve Cash Payment As Admin

1. Make the request "Update Payment As Approved"
2. Expected Response Code : 204.
3. Expected Response Body : null


N.B  : It should also be possible for an admin to directly make the cash payment on behalf of the user, by passing the payment_status as 1, in request (39), so that it is directly approved. In that case, refer to __proxy_user_settings__, because additional proxy settings have to be sent through, to allow the admin to do something on behalf of the user.
Make a provision for this request also.


<a href="Make_Card_Payment" /a>

## let me create two cart items as the other user, then add them to a cart, and then make a card payment as him, then approve it as admin.

### [41. Make Card Payment To Cart]
    
1. Do same as request (39), but with payment_type == "card"
2. Same response code, and response body is expected.


```
{
    "_id": {
        "$oid": "5a88a8f1421aa93fd40ee2ff"
    },
    "amount": 120000,
    "cart_id": "5a88a123421aa93e59e4addc",
    "cash_change": 0,
    "created_at": "2018-02-17T22:13:05.316Z",
    "discount_id": null,
    "gateway_callback_called": false,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "card",
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-17T22:13:05.316Z",
    "payment_receipt": null
}
```
    
<a href="Approve_Card_Payment" /a>

### [42. Approve Card Payment As Admin]

1. First direct the user to create an image resource, using the payment id, using request (X)
2. Now do request (40)
3. Same response code and body is expected.


<a href="Make_Cheque_Payment" /a>

### [43. Make Cheque Payment To Cart]

1. Do same as request (39), but with payment_type == "card"
2. Same response code, and response body is expected.



<a href="Approve_Cheque_Payment" /a>

### [44. Approve Cheque Payment As Admin]

1. First direct the user to create an image resource, using the payment id. 
2. Now do request (40)
3. Same response code and body is expected.



<a href="Disapprove_Payment" /a>

### 45. Disapprove an Approved Payment

1. Make Request 40, but with payment status as 0.

Expected Response code, and body is same.


<a href="Cancel_Cart_item_As_Admin" /a>

### 46. Cancel A Cart Item As Admin, After Payment Has been Made

1. Make Request (36) using Admin headers.
2. Show the cart using request 37, and it should show a negative cart balance.

<a href="Make_Refund_Request" /a>

### [47. Make Refund Request]

1. Make A Request to "Create A Refund"
2. The amount has to be equal to the cart pending balance.
3. The payment_type can be anything out of "cash, card,cheque"
4. The expected response code is 201
5. The expected response is : 

```
{
    "_id": {
        "$oid": "5a897049421aa94f2bec9910"
    },
    "amount":120000,
    "cart_id": "5a88a123421aa93e59e4addc",
    "cash_change": 0,
    "created_at": "2018-02-18T12:23:37.018Z",
    "discount_id": null,
    "gateway_callback_called": false,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "card",
    "public": "no",
    "refund": true,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-18T12:23:37.018Z",
    "payment_receipt": null
}
```

<a href="Approve_Refund_Request" a/>

### 48. Approve Refund Request As Admin

1. Make a Request to "Approve Refund Request As Admin"

2. Use the Admin headers

3. While making the request use the payment id of the refund payment.

4. Also add the "proxy_resource_class"> as the model class "User", and the "proxy_resource_id" as the id of the user who created the refund payment.

5. Before making the request, upload an image of the cheque that is being made for this purpose, using the request(X).

6. That will be validated while approving the payment.

7. Expected Response Code is 204.

8. Expected Response Body is null.

9. Check the cart_pending_balance by doing request "View Cart" and you should see a pending_balance of 0.


<a href="Refresh_Cart_Item" \a>

### 49. Refresh Cart Item

1. This request is to be performed to check if the cart_item is really "accepted" or not. This is done, in cases where a payment may have set a cart item as accepted, but later its own payment status was not set as "approved."

2. Make the request "Refresh Cart Item"

3. While making the request, you can either use for authentication the headers of the user who has made the cart item, or use admin headers, and add proxy_user_class and proxy_user_id in the body.

4. Expected Response is 204.

5. Expected Response Body is null.


<a href="Refresh Payment" /a>


### 49a. Refresh a Payment to retrospectively accept or reject cart items.

1. This request can be performed on any payment of the cart.
2. But it should always be performed on the last payment, so that that payment is considered as the one which accepts/rejects any pending cart items.
3. Make the Request "Update A Payment, to refresh cart balance and cart item statuses"
4. You can do it as admin(with proxy user setting), or as a user.
5. Expected Response code : 204.
6. Expected Response body : null.
7. After making the request> Do request (37), to view the cart and see the updated statuses of all the cart items.

<a href="Create_Gateway_Payment" /a>

### [50. Create A Gateway Payment]




1. Make a request "Create Gateway Payment"
 some fields are necessary to be entered by the user:
 1. firstname (if the user name is present, then autopopulate)
 2. phone (if the additional login param is present , then autopopulate, otherwise tell the user to enter it.)
 3. email (if the email  is present, then autopopulate, otherwise tell the user to enter it.)
 4. productinfo : this field, is to be autopopulated as: "items_{cart_id}"


2. Expected Response is : 201

3. Expected Response Body : 


```
{
    "_id": {
        "$oid": "5a8aaf96421aa903bf8ef5e3"
    },
    "amount": 240000,
    "cart_id": "5a88a123421aa93e59e4addc",
    "cash_change": 0,
    "created_at": "2018-02-19T11:05:58.234Z",
    "discount_id": null,
    "gateway_callback_called": false,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "gateway",
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T11:05:58.234Z",
    "payment_receipt": null
}
```

4. After creating the payment, forward the user to the gateway to do their payment.

5. the gateway at the end will ask to do a callback to the website. After that is completed, go to request (51) :
i.e (51)



<a href="Verify_Gateway_Payment" /a>

### [51. Verify Gateway Payment]

1. Make the Request "Verify Gateway Payment"

2. Expected Response Code : 204

3. Expected Response Body : null

4. In case of validation errors, only show the first error : 


```
{
    "errors": {
        "payment_status": [
            "status key is neither 1 not 0 : Please try to verify your payment later, or contact Support for more help."
        ],
        "firstname": [
            "can't be blank"
        ],
        "email": [
            "can't be blank"
        ],
        "phone": [
            "can't be blank"
        ],
        "productinfo": [
            "can't be blank"
        ]
    }
}
```


<a href="Get_Payment_Receipt" a />

### 51a. Get Payment Receipt

1. Make Request "Get Payment"
2. Payment Receipt is included in the response.
3. Only show the payment receipt if the payment status is accepted(1).
4. Expected Response Code : 200
4. Expected Response Body :

```
{
    "_id": {
        "$oid": "5a8aaf96421aa903bf8ef5e3"
    },
    "amount": 240000,
    "cart_id": "5a88a123421aa93e59e4addc",
    "cash_change": 0,
    "created_at": "2018-02-19T11:05:58.234Z",
    "discount_id": null,
    "gateway_callback_called": false,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "gateway",
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T11:05:58.234Z",
    "payment_receipt": {
        "current_payment": [],
        "cart": {
            "_id": {
                "$oid": "5a88a123421aa93e59e4addc"
            },
            "public": "no",
            "_type": "Shopping::Cart",
            "resource_id": "5a88a060421aa93e59e4add7",
            "resource_class": "User",
            "updated_at": "2018-02-17T21:39:47.243Z",
            "created_at": "2018-02-17T21:39:47.243Z",
            "cart_items": [
                "5a89c3ef421aa9614314ed99",
                "5a89e17d421aa96e604c8b07",
                "5a8aacc9421aa903bf8ef5e2"
            ],
            "cart_payments": [
                "5a88a8f1421aa93fd40ee2ff",
                "5a897049421aa94f2bec9910",
                "5a89ac83421aa95973dda71d",
                "5a8aaf96421aa903bf8ef5e3"
            ]
        }
    }
}
``` 

<a href="Create_Discont_Coupon_From_Cart" /a>

### 52. Create A Discount Coupon From A Cart



1. After A User has made one approved payment to a cart, he can create discount coupons. 
2. To create a discount coupon , make the request "Create Discount Coupon."
3. Following options have to be filled in by the user.

- discount_Amount : the discount amount is normally equal to the sum of the prices of accepted items(1 each.) for.eg:

Imagine that the cart has
2 apples - USD 30
2 bananas - USD 40

In this case the max discount amount will be : USD 35 (basically it assumes that this cart has been made with two users in mind, and each will take 1 piece of each item). Whatever the case, the max discount amount is 35. 
So you can show the user the option to set a discount amount upto 35.
To calculate this, just take the sum of 1 piece of each item that has been ACCEPTED.

- requires_verification

Inform the user that he has to set this as true, if he wants to be notified, everytime someone wants to use a discount coupon, made by him.

This is left false by default.

4. The expected response code is 201 Created.

5. The expected response body is the created discount item as follows: 

```
{
    "_id": {
        "$oid": "5a8b14c8421aa909d40e1c93"
    },
    "cart_id": "5a8af6d3421aa90c2b93fb88",
    "count": 4,
    "created_at": "2018-02-19T18:17:44.275Z",
    "declined": [],
    "discount_amount": 120000,
    "discount_percentage": 0,
    "pending": [],
    "product_ids": [
        "5a88618a421aa916385a3b45"
    ],
    "public": "yes",
    "requires_verification": true,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T18:17:44.275Z",
    "used_by_users": [],
    "verified": []
}
```


<a href="View_Discount_Coupon" /a>

### 53. View A Discount Coupon

N.B : unauthenticated user can view the discount coupon if he or she has the id.

1. Make the request "View Discount Coupon."

2. Expected Response code : 200

3. Expected Response : 


```
{
    "_id": {
        "$oid": "5a8b14c8421aa909d40e1c93"
    },
    "cart_id": "5a8af6d3421aa90c2b93fb88",
    "count": 4,
    "created_at": "2018-02-19T18:17:44.275Z",
    "declined": [],
    "discount_amount": 120000,
    "discount_percentage": 0,
    "pending": [],
    "product_ids": [
        "5a88618a421aa916385a3b45"
    ],
    "public": "yes",
    "requires_verification": true,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T18:17:44.275Z",
    "used_by_users": [],
    "verified": []
}
```



<a href="Create_Cart_From Discount_Coupon" /a>

### 54. Create Cart From Discount Coupon

1. The user has to be authenticated to do this.
2. Make A Request to "Create Cart Items from Discount"

- the "id" to be provided in the body is the discount_object id.

- the product_ids to be provided should be the same as the product ids, seen in the discount object.

3. Expected Response Code: 200

4. Expected Response Body: null

5. The response has to contain the cart_items as json objects

```
[
    {
        "_id": {
            "$oid": "5a8b49f0e13823140f39667b"
        },
        "accept_order_at_percentage_of_price": 1,
        "accepted": false,
        "accepted_by_payment_id": null,
        "created_at": "2018-02-17T17:08:26.373Z",
        "discount": null,
        "discount_code": null,
        "name": "Ford Ecosport",
        "parent_id": null,
        "price": "120000.0",
        "product_id": "5a88618a421aa916385a3b45",
        "public": "no",
        "quantity": 1,
        "resource_class": "User",
        "resource_id": "5a8b176a421aa90bbcc1b58d",
        "updated_at": "2018-02-17T17:08:26.373Z"
    }
]
```


5. Now make request (34a)

Final Expected Response :

```
{
    "_id": {
        "$oid": "5a8b4a41e13823140f39667c"
    },
    "created_at": "2018-02-19T22:05:53.260Z",
    "discount_id": null,
    "name": null,
    "notes": null,
    "public": "no",
    "resource_class": "User",
    "resource_id": "5a8b176a421aa90bbcc1b58d",
    "updated_at": "2018-02-19T22:05:53.260Z",
    "cart_items": [
        {
            "_id": {
                "$oid": "5a8b49f0e13823140f39667b"
            },
            "accept_order_at_percentage_of_price": 1,
            "accepted": null,
            "accepted_by_payment_id": null,
            "created_at": "2018-02-17T17:08:26.373Z",
            "discount": null,
            "discount_code": null,
            "name": "Ford Ecosport",
            "parent_id": "5a8b4a41e13823140f39667c",
            "price": "120000.0",
            "product_id": "5a88618a421aa916385a3b45",
            "public": "no",
            "quantity": 1,
            "resource_class": "User",
            "resource_id": "5a8b176a421aa90bbcc1b58d",
            "updated_at": "2018-02-19T22:05:53.212Z"
        }
    ],
    "cart_payments": [],
    "cart_price": "120000.0",
    "cart_paid_amount": 0,
    "cart_pending_balance": "120000.0",
    "cart_credit": 0,
    "cart_minimum_payable_amount": "120000.0"
}
```


6. Now proceed to (55)





<a href="Make_Payment_To_Cart_Using_Discount_Coupon" /a>

### 55. Make Payment Into Cart Using Discount Coupon]


1. Make the request : Create Discount Payment.

2. While doing this, set the amount to 0.0

3. Expected Response Code : 201

4. Expected Response Body : 

```
{
    "_id": {
        "$oid": "5a8b4b10e13823140f39667d"
    },
    "amount": 120000,
    "cart_id": "5a8b4a41e13823140f39667c",
    "cash_change": 0,
    "created_at": "2018-02-19T22:09:21.038Z",
    "discount_id": "5a8b14c8421aa909d40e1c93",
    "email": null,
    "firstname": null,
    "furl": null,
    "gateway_callback_called": false,
    "hast": null,
    "payment_ack_proof": null,
    "payment_status": null,
    "payment_type": "cash",
    "phone": null,
    "productinfo": null,
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a8b176a421aa90bbcc1b58d",
    "surl": null,
    "txnid": null,
    "updated_at": "2018-02-19T22:09:21.038Z",
    "payment_receipt": null
}
```

*N.B : the amount is automatically set to the discount amount.

After this , go back to Request 53, to view the discount and it should show the payment in the pending ids

```
{
    "_id": {
        "$oid": "5a8b14c8421aa909d40e1c93"
    },
    "cart_id": "5a8af6d3421aa90c2b93fb88",
    "count": 4,
    "created_at": "2018-02-19T18:17:44.275Z",
    "declined": [],
    "discount_amount": 120000,
    "discount_percentage": 0,
    "pending": [
        "5a8b4b10e13823140f39667d"
    ],
    "product_ids": [
        "5a88618a421aa916385a3b45"
    ],
    "public": "yes",
    "requires_verification": true,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T18:17:44.275Z",
    "used_by_users": [],
    "verified": []
}
```


<a href="Verify_Discount_Coupon_Request" /a>

### [56. Verify_Discount_Coupon_Request]

1. Make the Request "Update A Discount to Add Verified Payment Id"

2. Add the headers of the owner of the discount.

3. Expected Response Code : 204

4. Expected Response Body : null

5. Once again do request : 53, and now that payment should be seen in verified_ids.

```
{
    "_id": {
        "$oid": "5a8b14c8421aa909d40e1c93"
    },
    "cart_id": "5a8af6d3421aa90c2b93fb88",
    "count": 4,
    "created_at": "2018-02-19T18:17:44.275Z",
    "declined": [],
    "discount_amount": 120000,
    "discount_percentage": 0,
    "pending": [],
    "product_ids": [
        "5a88618a421aa916385a3b45"
    ],
    "public": "yes",
    "requires_verification": true,
    "resource_class": "User",
    "resource_id": "5a88a060421aa93e59e4add7",
    "updated_at": "2018-02-19T22:15:43.745Z",
    "used_by_users": [],
    "verified": [
        "5a8b4b10e13823140f39667d"
    ]
}
```


### [57. Decline Discount Coupon Request](Decline_Discount_Coupon_Request)


### [58. Use the Approved Discount Coupon](Use_Approved_Discount_Coupon)

1. Make the Request 51
2. Expected Response Code : 204.
3. Expected Response Body : null
4. Check the cart to see, that the discount_coupon payment has been accepted.


```
{
    "_id": {
        "$oid": "5a8b4a41e13823140f39667c"
    },
    "created_at": "2018-02-19T22:05:53.260Z",
    "discount_id": null,
    "name": null,
    "notes": null,
    "public": "no",
    "resource_class": "User",
    "resource_id": "5a8b176a421aa90bbcc1b58d",
    "updated_at": "2018-02-19T22:05:53.260Z",
    "cart_items": [
        {
            "_id": {
                "$oid": "5a8b49f0e13823140f39667b"
            },
            "accept_order_at_percentage_of_price": 1,
            "accepted": true,
            "accepted_by_payment_id": "5a8b4b10e13823140f39667d",
            "created_at": "2018-02-17T17:08:26.373Z",
            "discount": null,
            "discount_code": null,
            "name": "Ford Ecosport",
            "parent_id": "5a8b4a41e13823140f39667c",
            "price": "120000.0",
            "product_id": "5a88618a421aa916385a3b45",
            "public": "no",
            "quantity": 1,
            "resource_class": "User",
            "resource_id": "5a8b176a421aa90bbcc1b58d",
            "updated_at": "2018-02-19T22:21:06.625Z"
        }
    ],
    "cart_payments": [
        {
            "_id": {
                "$oid": "5a8b4b10e13823140f39667d"
            },
            "amount": 120000,
            "cart_id": "5a8b4a41e13823140f39667c",
            "cash_change": 0,
            "created_at": "2018-02-19T22:09:21.038Z",
            "discount_id": "5a8b14c8421aa909d40e1c93",
            "email": null,
            "firstname": null,
            "furl": null,
            "gateway_callback_called": false,
            "hast": null,
            "payment_ack_proof": null,
            "payment_status": 1,
            "payment_type": "cash",
            "phone": null,
            "productinfo": null,
            "public": "no",
            "refund": null,
            "resource_class": "User",
            "resource_id": "5a8b176a421aa90bbcc1b58d",
            "surl": null,
            "txnid": null,
            "updated_at": "2018-02-19T22:21:06.679Z",
            "payment_receipt": null
        }
    ],
    "cart_price": "120000.0",
    "cart_paid_amount": 120000,
    "cart_pending_balance": "0.0",
    "cart_credit": 120000,
    "cart_minimum_payable_amount": 0
}
```

### [59. Create Cartless Discount Coupon](Create_Cartless_Discount_Coupon)

1. Make the Request "Create Cartless Discount"
2. This time , do not add a cart_id
3. You can add both discount_amount and discount_percentage. If both provided, then discount_amount will be used.
4. Discount percentage is calculated as the percentage of the total cart_pending_balance, at the time the discount payment is made.
5. You must specify a count, i.e the number of times this discount can be used.
6. Requires verification can be left blank, in which case a user can directly use that discount coupon, without the admin having to verify it.
5. Expected Response Code : 201
6. Expected Response Body : 

N.B : This request can only be performed by admin.

```
{
    "_id": {
        "$oid": "5a8b524c421aa9163c04f6f5"
    },
    "cart_id": null,
    "count": 5,
    "created_at": "2018-02-19T22:40:12.519Z",
    "declined": [],
    "discount_amount": 0,
    "discount_percentage": 100,
    "pending": [],
    "product_ids": [],
    "public": "yes",
    "requires_verification": false,
    "resource_class": "User",
    "resource_id": "5a870959421aa90f36a35558",
    "updated_at": "2018-02-19T22:40:12.519Z",
    "used_by_users": [],
    "verified": []
}
```


### [60. Use Cartless Discount Coupon](Use_Cartless_Discount_Coupon)


1. Any user can use this discount coupon directly into their carts.
2. Make the request "Create A Discount Payment".
3. Expected Response Code is same, except that in this case, it will be directly accepted and verified, without the need for an admin verification.
4. Expected Response Code : 201
5. Expected Response Body :

```
{
    "_id": {
        "$oid": "5a8b5286421aa9163c04f6f6"
    },
    "amount": 120000,
    "cart_id": "5a8b4a41e13823140f39667c",
    "cash_change": 0,
    "created_at": "2018-02-19T22:41:10.572Z",
    "discount_id": "5a8b524c421aa9163c04f6f5",
    "email": null,
    "firstname": null,
    "furl": null,
    "gateway_callback_called": false,
    "hast": null,
    "payment_ack_proof": null,
    "payment_status": 1,
    "payment_type": "cash",
    "phone": null,
    "productinfo": null,
    "public": "no",
    "refund": null,
    "resource_class": "User",
    "resource_id": "5a8b176a421aa90bbcc1b58d",
    "surl": null,
    "txnid": null,
    "updated_at": "2018-02-19T22:41:10.572Z",
    "payment_receipt": {
        "current_payment": [
            {
                "_id": {
                    "$oid": "5a8b51da421aa9163c04f6f4"
                },
                "accept_order_at_percentage_of_price": 1,
                "accepted": true,
                "accepted_by_payment_id": "5a8b5286421aa9163c04f6f6",
                "created_at": "2018-02-19T22:38:18.366Z",
                "discount": null,
                "discount_code": null,
                "name": "Ford Ecosport",
                "parent_id": "5a8b4a41e13823140f39667c",
                "price": "120000.0",
                "product_id": "5a88618a421aa916385a3b45",
                "public": "no",
                "quantity": 1,
                "resource_class": "User",
                "resource_id": "5a8b176a421aa90bbcc1b58d",
                "updated_at": "2018-02-19T22:41:10.525Z"
            }
        ],
        "cart": {
            "_id": {
                "$oid": "5a8b4a41e13823140f39667c"
            },
            "public": "no",
            "_type": "Shopping::Cart",
            "resource_id": "5a8b176a421aa90bbcc1b58d",
            "resource_class": "User",
            "updated_at": "2018-02-19T22:05:53.260Z",
            "created_at": "2018-02-19T22:05:53.260Z",
            "cart_items": [
                "5a8b49f0e13823140f39667b",
                "5a8b51da421aa9163c04f6f4"
            ],
            "cart_payments": [
                "5a8b4b10e13823140f39667d"
            ]
        }
    }
}
```

