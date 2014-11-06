---
layout: page
title: Handling Failure
---

# Handling Failure

We've now seen everything we need to read and write arbitrary JSON data. We are almost ready to create full-featured JSON REST APIs. There's only one more thing we need to cover: failure.

When a JSON REST endpoint fails, it needs to return JSON to the client. We can do this manually in the case of expected errors, but what about unexpected errors such as exceptions?

In this section we will look at replacing Play's default 400 and 500 error pages with our own JSON error pages. We'll do this by writing some simple error handlers using Play's `Global` object.

## The *Global* Object

We can configure various HTTP-handling aspects of our applications by creating an object called `Global` in the `_root_` package. The object should extend [play.api.GlobalSettings], which provides various methods that we can override:

~~~ scala
package _root_

import play.api._

object Global extends GlobalSettings {
  // custom configuration goes here...
}
~~~

[play.api.GlobalSettings]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.GlobalSettings

### Custom Routing Error Pages

We can change the default routing error page by overriding the `onHandlerNotFound` method. Here's an example that returns some suitable JSON to log an error on the client:

~~~ scala
import play.api.libs.concurrent.Execution.Implicits.defaultContext
import play.api.libs.json._
import scala.concurrent.Future

object Global extends GlobalSettings {
  override def onHandlerNotFound(request: RequestHeader): Future[Result] = {
    Logger.warn(s"Error 404: ${request.method} ${request.uri}")

    Future(NotFound(Json.obj(
      "type"    -> "error",
      "status"  -> 404,
      "message" -> s"Could not route request: ${request.method} ${request.uri}"
    )))
  }
}
~~~

Note that the method accepts a `RequestHeader` and returns a `Future[Result]`. The `RequestHeader` type indicates that the body of the request may not yet have been read. The `Future` return type allows us to call external logging services before we return a `Result`.

We can also provide a custom response when Play is able to route a request but is unable to parse the URL parameters:

~~~ scala
object Global extends GlobalSettings {
  override def onBadRequest(request: RequestHeader): Future[Result] = {
    Logger.warn(s"Error 404: ${request.method} ${request.uri}")

    Future(NotFound(Json.obj(
      "type"    -> "error",
      "status"  -> 400,
      "message" -> s"Bad request data: ${request.method} ${request.uri}"
    )))
  }
}
~~~

### Custom Application Error Pages

We can change the default exception page by overriding the `onError` method. The principle is similar to that for `onHandlerNotFound`:

~~~ scala
object Global extends GlobalSettings {
  override def onError(request: RequestHeader, exn: Throwable) = {
    Logger.warn(s"Error 500: ${exn.getMessage}", exn)

    InternalServerError(Json.obj(
      "type"    -> "error",
      "status"  -> 500,
      "message" -> exn.getMessage
    ))
  }
}
~~~

## Take Home Points

We can customise various aspects of our application's general behaviour by providing a `_root_.Global` object. The object must extend [play.api.GlobalSettings].

`GlobalSettings` contains several methods that we can override to custom error responses:

 - `onHandlerNotFound` allows us to customise responses when Play cannot route a request;
 - `onBadRequest` allows us to customise responses when Play cannot extract URL parameters;
 - `onError` allows us to customise responses triggered by unhandled exceptions.

There are also some other useful methods not covered above:

 - `onStart` allows us to hook into the application's startup process;
 - `onStop` allows us to hook into the application's shutdown process;
 - `doFilter` allows us to provide custom HTTP filters,
   for example adding JSONP, logging, or CORS support to every request.

[play.api.GlobalSettings]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.GlobalSettings
