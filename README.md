## AUTH

### Why This Gem?

#### Authentication

Rails does not offer an all-in-one , plug and play style authentication gem.
This Gem provides:

1. Basic Username, Password Authentication
2. Mobile, Password Authentication
3. OAuth Authentication
4. Token based authentication
5. API authentication
6. Authentication mechanism for Chrome Extensions
7. Standard authentication features like forgot your password, unlock your account and resend confirmation email etc.

#### Notifications

Rails does not provide a simple interface for notifications (email/sms)
This Gem provides a simple Notify class that can be called from anywhere to send email/sms notifications.

#### Shopping Cart

Rails also does not have a shopping-cart gem that works easily.
This Gem provides full shopping cart functionality.

#### Drawbacks:

The only drawback for the moment, is that the gem is built around MongoDb as the database backend. We are working on letting you use adapters for RDBS

### How to Use:

Create a new Rails project from the command line:

```
rails new {your app name} --skip-active-record
```

Edit the Gemfile to include the following:

```

```


