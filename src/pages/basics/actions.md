## Actions, Controllers, and Routes

We create Play web applications from *actions*, *controllers*, and *routes*.
In this section we will see what each part does and how to wire them together.


### Hello, World!

*Actions* are objects that handle web requests.
They have an `apply` method that accepts a [`play.api.mvc.Request`]
and returns a [`play.api.mvc.Result`]

~~~ scala
Action { request =>
  Ok("Hello, world!")
}
~~~

We package actions inside `Controllers`.
These are singleton objects that contain action-producing methods:

~~~ scala
package controllers

import play.api.mvc.{ Action, Controller }

object HelloController extends Controller {
  def hello = Action { request =>
    Ok("Hello, world!")
  }

  def helloTo(name: String) = Action { request =>
    Ok(s"Hello, $name!")
  }
}
~~~

We use *routes* to dispatch incoming requests to `Actions`.
Routes choose `Actions` based on the *HTTP method* and *path* of the request.
We write routes in a Play-specific DSL that is compiled to Scala by SBT:

~~~ bash
GET /      controllers.HelloController.hello
GET /:name controllers.HelloController.helloTo(name: String)
~~~

We'll learn more about this DSL in the next section.
By convention we place controllers in the `controllers` package
in the `app/controllers` folder, and routes in a `conf/routes` configuration file.
This is the structure of a basic Play application:

~~~ coffee
myProject/
  build.sbt                 # SBT project configuration
  project/
    plugins.sbt             # SBT plugin configuration
  app/
    controllers/            # Controllers and actions go here
      HelloController.scala #
  conf/
    routes                  # Routes go here
~~~

### The Anatomy of a Controller

Let's take a closer look at the controller in the example above.
The code in use comes from two places:

 - the [`play.api.mvc`] package;
 - the [`play.api.mvc.Controller`] trait (via inheritance).

The controller, called `HelloController`, is a subtype of [`play.api.mvc.Controller`].
It defines two `Action`-producing methods, `hello` and `helloTo`.
Our routes specify which of these methods to call when a request comes in.

Note that `Actions` and `Controllers` have different lifetimes.
`Controllers` are created when our application boots and persist until it shuts down.
`Actions` are created and executed in response to incoming `Requests` and have a much shorter lifespan.
Play passes parameters from our routes to *the method that creates the `Action`*,
not to the action itself.

Each of the example `Actions` creates an `Ok` response containing a simple message.
`Ok` is a helper object inherited from `Controller`.
It has an `apply` method  that creates `Results` with HTTP status 200.
The actual return type of `Ok.apply` is [`play.api.mvc.Result`].

Play uses the type of the argument to `Ok.apply` to determine the `Content-Type` of the `Result`.
The `String` arguments in the example create a `Results` of type `text/plain`.
Later on we'll see how to customise this behaviour and create results of different types.


### Take Home Points

The backbone of a Play web application is made up of `Actions`, `Controllers`, and *routes*:

 - `Actions` are functions from `Requests` to `Results`;

 - `Controllers` are collections of action-producing methods;

 - Routes map incoming `Requests` to `Action`-producing method calls on our `Controllers`.

We typically place controllers in a `Controllers` package in the `app/controllers` folder.
Routes go in the `conf/routes` file (no filename extension).

In the next section we will take a closer look at routes.


### Exercise: Time is of the Essence

The `chapter3-time` directory in the exercises contains
an unfinished Play application for telling the time.

Complete this application by filling in the missing actions and routes.
Implement the three missing actions described
in the comments in `app/controllers/TimeController.scala`
and complete the `conf/routes` file to hook up the specified URLs.

We've written this project using the [Joda Time](link-joda-time) library
to handle time formatting and time zone conversion.
Don't worry if you haven't used the library before---the `TimeHelpers` trait
in `TimeController.scala` contains all of the functionality needed
to complete the task at hand.

Test your code using `curl` if you're using Linux or OS X,
or a browser if you're using Windows:

~~~ bash
bash$ curl -v 'http://localhost:9000/time'
# HTTP headers...
4:18 PM

bash$ curl -v 'http://localhost:9000/time/zones'
# HTTP headers...
Africa/Abidjan
Africa/Accra
Africa/Addis_Ababa
# etc...

bash$ curl -v 'http://localhost:9000/time/CET'
# HTTP headers...
5:21 PM

bash$
~~~

<div class="callout callout-info">
*Be agile!*

Complete the exercises by coding small units of end-to-end functionality.
Start by implementing the simplest possible action that you can test on the command line:

~~~ scala
// Action:
def time = Action { request =>
  Ok("TODO: Complete")
}

// Route:
GET /time controllers.TimeController.time
~~~

Write the route for this action and test it using `curl` before you move on.
The faster you get to running your code, the faster you will learn from any mistakes.
</div>

Questions:

1. What happens when you connect to the application using the following URL?
Why does this not work as expected and how can you work around the behaviour?

    ~~~ bash
    bash$ curl -v 'http://localhost:9000/time/Africa/Abidjan'
    ~~~

2. What happens when you send a `POST` request to the application?

    ~~~ bash
    bash$ curl -v -X POST 'http://localhost:9000/time'`
    ~~~

<div class="solution">
The main task in the actions in `TimeController.scala` is
to convert the output of the various methods in `TimeHelpers` to a `String`
so we can wrap it in an `Ok()` response:

~~~ scala
def time = Action { request =>
  Ok(timeToString(localTime))
}

def timeIn(zoneId: String) = Action { request =>
  val time = localTimeInZone(zoneId)
  Ok(time map timeToString getOrElse "Time zone not recognized.")
}

def zones = Action { request =>
  Ok(zoneIds mkString "\n")
}
~~~

Hooking up the routes would be straightforward,
except we included one gotcha to trip you up.
You must place the route for `TimeController.zones`
*above* the route for `TimeController.timeIn`:

~~~ bash
GET /time        controllers.TimeController.time
GET /time/zones  controllers.TimeController.zones
GET /time/:zone  controllers.TimeController.timeIn(zone: String)
~~~

If you put these two in the wrong order,
Play will treat the word `zones` in `/time/zones`
as the name of a time zone and route the request to `TimeController.timeIn("zones")`
instead of `TimeController.zones`.

The answers to the questions are as follows:

1.  The mistake here is that we haven't escaped the `/` in `Africa/Abidjan`.
    Play interprets this as a path with three segments but our route will only match two.
    The result is a 404 response.

    If we encode the value as `Africa%2FAbidjan` the application will respond as desired.
    The `%2F` is decoded by Play before the argument is passed to `timeIn`:

    ~~~ bash
    bash$ curl 'http://localhost:9000/time/Africa%2FAbidjan'
    4:38 PM
    ~~~

2.  Our routes are only configured to match incoming `GET` requests
    so `POST` requests result in a 404 response.
</div>
