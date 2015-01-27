## Routes in Depth

The previous section introduced `Actions`, `Controllers`, and routes.
`Actions` and `Controllers` are standard Scala code,
but routes are something new and specific to Play.

We define Play routes using a special DSL that compiles to Scala code.
The DSL provides both a convenient way of mapping URIs to method calls
and a way of mapping method calls *back* to URIs.
In this section we will take a deeper look at Play's routing DSL
including the various ways we can extract parameters from URIs.

### Path Parameters

Routes associate *URI patterns* with *action-producing method calls*.
We can specify *parameters* to extract from the URI and pass to our controllers.
Here are some examples:

~~~ coffee
# Fixed route (no parameters):
GET /hello controllers.HelloController.hello

# Single parameter:
GET /hello/:name controllers.HelloController.helloTo(name: String)

# Multiple parameters:
GET /send/:msg/to/:user ↩
  controllers.ChatController.send(msg: String, user: String)

# Rest-style parameter:
GET /download/*filename ↩
  controllers.DownloadController.file(filename: String)
~~~

The first example assocates a single URI with a parameterless method.
The match must be exact---only `GET` requests to `/hello` will be routed.
Even a trailing slash in the URI (`/hello/`) will cause a mismatch.

The second example introduces a *single-segment parameter*
written using a leading colon (':').
Single-segment parameters match any continuous set of characters
*excluding* forward slashes ('/').
The parameter is extracted and passed
to the method call---the rest of the URI must match exactly.

The third example uses two single-segment parameters
to extract two parts of the URI.
Again, the rest of the URI must match exactly.

The final example uses a *rest-parameter*
written using a leading asterisk ('*').
Rest-style parameters match all remaining characters in the URI,
including forward slashes.

### Matching Requests to Routes

When a request comes in, Play attempts to route it to an action.
It examines each route in turn until it finds a match.
If no routes match, it returns a 404 response.

Routes match if the HTTP method has the relevant value
and the URI matches the shape of the pattern.
Play supports all eight HTTP methods:
`OPTIONS`, `GET`, `HEAD`, `POST`, `PUT`, `DELETE`, `TRACE`, and `CONNECT`.

:Routing examples---mappings from HTTP data to Scala code

---------------------------------------------------------------------------------------------
HTTP method and URI                Scala method call or result
---------------------------------- ----------------------------------------------------------
`GET  /hello`                      `controllers.HelloController.hello`

`GET  /hello/dave`                 `controllers.HelloController.helloTo("dave")`

`GET  /send/hello/to/dave`         `controllers.ChatController.send("hello", "dave")`

`GET  /download/path/to/file.txt`  `controllers.DownloadController.file("path/to/file.txt")`

`GET  /hello`/                     404 result (trailing slash)

`POST /hello`                      404 result (POST request)

`GET  /send/to/dave`               404 result (missing path segment)

`GET  /send/a/message/to/dave`     404 result (extra path segment)
---------------------------------------------------------------------------------------------

<div class="callout callout-info">
*Play Routing is Strict*

Play's strict adherance to its routing rules can sometimes be problematic.
Failing to match the URI `/hello/`, for example, may seem overzealous.
We can work around this issue easily
by mapping multiple routes to a single method call:

~~~ coffee
GET  /hello  controllers.HelloController.hello # no trailing slash
GET  /hello/ controllers.HelloController.hello # trailing slash
POST /hello/ controllers.HelloController.hello # POST request
# and so on...
~~~
</div>

### Query Parameters

We can specify parameters in the method-call section
of a route without declaring them in the URI.
When we do this Play extracts the values from the query string instead:

~~~ coffee
# Extract `username` and `message` from the path:
GET /send/:message/to/:username ↩
  controllers.ChatController.send(message: String, username: String)

# Extract `username` and `message` from the query string:
GET /send ↩
  controllers.ChatController.send(message: String, username: String)

# Extract `username` from the path and `message` from the query string:
GET /send/to/:username ↩
  controllers.ChatController.send(message: String, username: String)
~~~

We sometimes want to make query string parameters optional.
To do this, we just have to define them as `Option` types.
Play will pass `Some(value)` if the URI contains the parameter
and `None` if it does not.

For example, if we have the following `Action`:

~~~ scala
object NotificationController {
  def notify(username: String, message: Option[String]) =
    Action { request => /* ... */ }
}
~~~

we can invoke it with the following route:

~~~ coffee
GET /notify controllers.NotificationController. ↩
  notify(username: String, message: Option[String])
~~~

We can mix and match required and optional query parameters as we see fit.
In the example, `username` is required and `message` is optional.
However, *path* parameters are always required---the following route
fails to compile because the path parameter `:message` cannot be optional:

~~~ coffee
GET /notify/:username/:message controllers.NotificationController. ↩
  notify(username: String, message: Option[String])

# Fails to compile with the following error:
#     [error] conf/routes:1: No path binder found for Option[String].
#     Try to implement an implicit PathBindable for this type.
~~~

### Typed Parameters

We can extract path and query parameters of types other than `String`.
Play has built-in support for `Int`, `Double`, `Long`, `Boolean`, `UUID`,
and `Option` and `Seq` variants:

~~~ coffee
GET /add/:a/to/:b controllers.Calculator.add(a: Int, b: Int)
~~~

This allows us to define `Actions` using well-typed arguments
without messy parsing code:

~~~ scala
object Calculator extends Controller {
  def add(a: Int, b: Int) = Action { request =>
    Ok(s"The answer is ${a + b}")
  }
}
~~~

If Play cannot extract values of the correct type for each parameter in a route,
it returns a *400 Bad Request* response to the client.
It doesn't consider any other routes lower in the file.

<div class="callout callout-warning">
*Custom Parameter Types*

Play parses route parameters using instances of two different *type classes*:

 - [`play.api.mvc.PathBindable`] to extract path parameters;
 - [`play.api.mvc.QueryStringBindable`] to extract query parameters.

We can implement custom parameter types
by creating implicit values these type classes.
See the linked Scaladocs for more information.
</div>

### Reverse Routing

*Reverse routes* are objects that we can use to generate URIs.
This allows us to create URIs from type-checked program code
without having to concatenate `Strings` by hand.

Play generates reverse routes for us
and places them in a `controllers.routes`
package that we can access from our Scala code:

~~~ scala
import play.api.mvc.Call

val methodAndUri: Call = routes.HelloController.helloTo("dave")

methodAndUri.method // "GET"
methodAndUrl.url    // "/hello/dave"
~~~

Play generates reverse routes for each controller
and action referenced in our routes file.
The routes return [`play.api.mvc.Call`] objects
that hold the HTTP method and URI from the route.
Here is some pseudo-code based on example above to illustrate:

~~~ scala
package routes

import play.api.mvc.Call

object HelloController {
  def hello: Call =
    Call("GET", "/hello")

  def helloTo(name: String): Call =
    Call("GET", "/hello/" + encodeURIComponent(name))
}

object ChatController {
  def send(msg: String, user: String): Call =
    Call("GET",
      "/send/" + encodeURIComponent(msg) +
      "/to/" + encodeURIComponent(user))
}

object DownloadController {
  def file(filename: String): Call =
    Call("GET", "/download/" + encodeURI(filename))
}
~~~

### Take Home Points

*Routes* provide bi-directional mapping between URIs and
`Action`-producing methods within `Controllers`.

We write routes using a Play-specific DSL that compiles to Scala code.
Each route comprises an HTTP method, a URI pattern,
and a corresponding method call.
Patterns can contain *path* and *query parameters*
that are extracted and used in the method call.

We can *type* the path and query parameters in routes
to simplify the parsing code in our controllers and actions.
Play supports many types out of the box,
but we can also write code to map our own types.

Play also generates *reverse routes* that map method calls back to URIs.
These are placed in a synthetic `routes` package
that we can access from our Scala code.

Now we have seen what we can do with routes,
let's look at the `Request` and `Result`
handling code we can write in our actions.
This will arm us with all the knowledge we need
to start dealing with HTML in the next chapter.
