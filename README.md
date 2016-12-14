###AUTH

##Why This Gem?
Integrating Devise with a Rails App is still a tiresome process.
These days, most web-services have clients on multiple platforms like Android, IOS, Chrome extensions, JS widgets etc.
There is no rails gem that provides a simplistic and easy to configure authentication system that supports all these needs.
Wordjelly Auth combines Devise, SimpleTokenAuthentication, OmniAuth2 and several other gems to provide a one-fits-all authentication solution.
Furthermore, having an authentication system is not enough without a shiny front-end. Wordjelly-Auth provides users with an optional authentication layout, using MaterializeCss.

The entire installation process requires just ONE inializer file. You do not need to run generators, configure heavy config.rb files, or do anything fancy to get this working. The estimated time to get this running is less than a minute.

##How to use:

Add 'wj-auth' to your gemfile




###To reference engine paths from within the engine:
If you don't do as below, you don't get the mount path prefixed to the url.
```
Engine_Name::Engine.routes.url_helpers.path
```

###To reference app paths from withing the engine:
There is a helper which is created when you mount any engine, called main_app
Use this from within the engine to reference app_paths.
```
main_app.app_path
```

###To reference engine paths from within the app:
While mounting the engine, specify as: mount_as
```
mount_as.engine_path
```

##While testing routes with rspec

1. If you are testing any action that involves a route defined in the engine,
then you need to use the routeset of the engine.
```
routes{Auth::Engine.routes}
```
Furthermore remember that using any path helpers, inside rspec, will give you the path including the mount_prefix(where you mounted the engine), however this path will not be found in the engine routeset above, and you will get a no route matches.
So you have to use raw paths i.e "clients" instead of clients_path because clients_path => mount_prefix/clients, which is not present in the routes defined in the engine. The engine routes contain everything relative to root(/). So whenever testing any action that involves an engine route, use raw paths and define the routeset. 

2. Don't create any actions that involve using an engine route and an app route, because it will be very difficult to test that.
