---
layout: page
title: Routing Requests
---

# Routing Requests

The previous section introduced actions and controllers, and associated them with URLs using a simple routes file. In this section we take a closer look at routes and the various things we can do with them.

# Path Parameters

The example route from the previous section associates a single URL with a single action:

~~~ coffee
GET /    controllers.HelloWorld.index
~~~

Routes are more flexibile than this -- they actually associate *URL patterns* with *action-producing method calls*. This allows us to specify *parameters* to be extracted from the URL and passed to our controller code. Here are some examples:

~~~ coffee
# A static route with a fixed URL (no parameters):
GET /hello/world                   controllers.HelloWorld.index

# A route with a single parameter:
GET /send/:message                 controllers.Notification.send(message: String)

# A route with two parameters:
GET /send/:message/to/:username    controllers.Notification.sendTo(message: String, username: String)

# A route with a rest-style parameter:
GET /download/*filename            controllers.Download.file(filename: String)
~~~

The first example assocates a fixed URL with the `index` method we defined earlier. It matches the URL `/hello/world` and routes it to the `index` method in the `HelloWorld` controller.

The second and third examples assocate URLs of the form `/send/...` and `/send/.../to/...` with the methods `send` and `sendTo` in the `Notification` controller. The `:` prefix means the parameters only match single path segments. So, for example:

 - the URL `/send/hi` would result in the method call `controllers.Notification.send("hi")`;
 - the URL `/send/bye` would result in the method call `controllers.Notification.send("bye")`;
 - the URL `/send/hi/to/dave` would result in the method call `controllers.Notification.sendTo("hi", "dave")`;
 - the following URLs would not match either rule, causing Play to continue processing the rest of the routes file:
    - `/send/hi/dave`
    - `/send/hi/to`
    - `/send/hello/there/to/dave`

The fourth and final example assocates URLs of the form `/download/...` with the method `Download.file`. The `*` prefix on the `*filename` parameter means it can match any sequence of characters, including `/` characters. So, for example, the URL `/download/my/file.txt` would result in the method call `controllers.Download.file("my/file.txt").

Methods referenced in the routes file must accept the same parameters as the route and return `Action` objects. Here is the controller code for `Notification` and `Download`:

~~~ scala
object Notification extends Controller {
  def send(message: String) = Action { request =>
    // ...
  }

  def sendTo(message: String, username: String) = Action { request =>
    // ...
  }
}

object Download extends Controller {
  def file(filename: String) = Action { request =>
    // ...
  }
}
~~~

# Query Parameters

If we specify a parameter in the method-call section of a route but not in the URL pattern, Play extracts it from the query parameters of the URL instead. For example:

~~~ coffee
GET /send    controllers.Notification.sendTo(message: String, username: String)
~~~

This route will match URLs of the form `/send?message=...&username=...` and convert them to method calls. If either query parameter is missing, the route fails to match and play proceeds processing the rest of the routes file.

# Typed Parameters

In addition to specifying parameters of type `String`, we can also specify parameters of other types by simply changing the type annotations in the route:

~~~ coffee
GET /add/:a/to/:b    controllers.Calculator.add(a: Int, b: Int)
~~~

This allows us to write action methods that take parameters of sane types:

~~~ scala
object Calculator extends Controller {
  def add(a: Int, b: Int) = Action { request =>
    Ok(s"The answer is ${a + b}")
  }
}
~~~

Play provides built-in support for parameters of type `java.lang.String`, `Int`, `Double`, `Long`, `Boolean`, and `java.util.UUID`. It also supports query parameters of `Option` and `Seq` variants of these types:

~~~ coffee
# Matches URLs of the form /todo/complete?item=1&item=2&item=3...
GET /todo/complete    controllers.Todo.complete(item: Seq[Int])
~~~

<div class="callout callout-info">
#### Advanced Typed Parameters

Play supports typed URL parameters using the *type class* pattern. It searches for implicit values of two type classes to see if it can decode an argument of a particular type:

 - path parameters are extracted using instances of [play.api.mvc.PathBindable];
 - query parameters are extracted using instances of [play.api.mvc.QueryStringBindable].

We can implement any type of URL parameter by creating an implicit value of one of these type classes and making it available in the compiled routes file. See the linked Scaladocs for more information.

[play.api.mvc.PathBindable]:        https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.PathBindable
[play.api.mvc.QueryStringBindable]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.QueryStringBindable
</div>

# Request Methods

Play supports all eight HTTP methods: `OPTIONS`, `GET`, `HEAD`, `POST`, `PUT`, `DELETE`, `TRACE`, and `CONNECT`.

A rule only matches a request if the method is as specified. For example, the following routes file sends all `GET` requests to `Example.handleGet`, all `POST` requests to `Example.handlePost`, and responds with a 404 to any other method:

~~~ coffee
GET  /*path controllers.Example.handleGet(path: String)
POST /*path controllers.Example.handlePost(path: String)
~~~

# Reverse Routing

In addition to creating a router for our application, Play also creates a set of *reverse route* objects that we can use to generate URLs for specific calls from our routes file. These are useful when writing RESTful web services in which result data must contain links to related resources.

By default, reverse route objects are placed in a top-level package called `routes` and structured as follows:

~~~ scala
routes.ControllerName.methodName(methodArgs...)
~~~

Reverse routes return objects of type [play.api.mvc.Call], which is a lightweight wrapper for a method and URL. Here is an example to demonstrate:

~~~ scala
object HelloWorld extends Controller {

  def index = Action { request =>
    val reverse: Call = routes.HelloWorld.index

    Ok(s"Hi! You found the action at ${request.method} ${request.uri},\n" +
       s"but the canonical route is ${reverse.method} ${reverse.url}.")
  }

}
~~~

If we go to [http://localhost:9000/foo](), we get the following response:

~~~
Hi! You found the action at GET /foo,
but the canonical route is GET /.
~~~

The first line of our output prints the method/URL we visited in our browser (`GET /foo`), while the second line always reports the "canonical" URL as `GET /`. This is because `/` and `/foo` are mapped to the same action in our routes file and `/` precedes `/foo`.

[play.api.mvc.Call]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Call

## Take Home Points

TODO