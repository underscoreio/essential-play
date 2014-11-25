## Actions, Controllers, and Routes

We create Play web applications from *actions*, *controllers*, and *routes*. In this section we will see what each part does and how to wire them together.

### Hello, World!

*Actions* are objects that handle web requests. They have an `apply` method that accepts a [`play.api.mvc.Request`] and returns a [`play.api.mvc.Result`]

~~~ scala
Action { request =>
  Ok("Hello, world!")
}
~~~

We package actions inside `Controllers`. These are singleton objects that contain action-producing methods:

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

We use *routes* to dispatch incoming requests to `Actions`. Routes choose `Actions` based on the *HTTP method* and *path* of the request. We write routes in a Play-specific DSL that is compiled to Scala by SBT:

~~~ bash
GET /      controllers.HelloController.hello
GET /:name controllers.HelloController.helloTo(name: String)
~~~

We'll learn more about this DSL in the next section. By convention we place controllers in the `controllers` package in the `app/controllers` folder, and routes in a `conf/routes` configuration file. This is the structure of a basic Play application:

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

Let's take a closer look at the controller in the example above. The code in use comes from two places:

 - the [`play.api.mvc`] package;
 - the [`play.api.mvc.Controller`] trait (via inheritance).

The controller, called `HelloController`, is a subtype of [`play.api.mvc.Controller`]. It defines two `Action`-producing methods, `hello` and `helloTo`. Our routes specify which of these methods to call when a request comes in.

Note that `Actions` and `Controllers` have different lifetimes. `Controllers` are created when our application boots and persist until it shuts down. `Actions` are created and executed in response to incoming `Requests` and have a much shorter lifespan. Play passes parameters from our routes to *the method that creates the `Action`*, not to the action itself.

Each of the example `Actions` creates an `Ok` response containing a simple message. `Ok` is a helper object inherited from `Controller`. It has an `apply` method  that creates `Results` with HTTP status 200. The actual return type of `Ok.apply` is [`play.api.mvc.Result`].

Play uses the type of the argument to `Ok.apply` to determine the `Content-Type` of the `Result`. The `String` arguments in the example create a `Results` of type `text/plain`. Later on we'll see how to customise this behaviour and create results of different types.


### Take Home Points

The backbone of a Play web application is made up of `Actions`, `Controllers`, and *routes*:

 - `Actions` are functions from `Requests` to `Results`;

 - `Controllers` are collections of action-producing methods;

 - Routes map incoming `Requests` to `Action`-producing method calls on our `Controllers`.

We typically place controllers in a `Controllers` package in the `app/controllers` folder. Routes go in the `conf/routes` file (no filename extension).

In the next section we will take a closer look at routes.
