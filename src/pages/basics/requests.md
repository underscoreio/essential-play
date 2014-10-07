---
layout: page
title: Parsing Requests
---

# Parsing Requests

As we saw in the previous section, when we create an `Action`, we typically do so by specifying a function of type `Request => Result`. We typically split this function into three stages:

 1. parse the `Request` into one or more Scala domain objects;
 2. perform our business logic using our domain objects;
 3. convert the result of our business logic into a `Result`.

This section covers the implementation of step 1 of this process: parsing requests.

## What's in a Request?

Clients can encode data into HTTP requests in a number of ways:

 - choice of HTTP method (GET, POST, etc);
 - path or query parameters in the URL;
 - headers and cookies;
 - request bodies.

The [play.api.mvc.Request] objects that Play passes to our actions contain methods for accessing all of this information.

[play.api.mvc.Request]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Request

### Methods and URIs

The suggested way of extracting this information is with a routes file. However, the `Request` object also contains methods for convenience:

~~~ scala
object RequestDemo extends Controller {
  def methodAndUri = Action { request =>
    // The HTTP method ("GET", "POST", etc):
    val method: String = request.method

    // The URI, including path and query string:
    val uri: String = request.uri

    // The path of the URI, without the query string:
    val path: String = request.uri

    // The query string, split into name/values pairs:
    val query: Map[String, Seq[String]] = request.queryString

    Ok(Seq(
      s"Method: $method",
      s"URI: $uri",
      s"Path: $path",
      s"Query: $query"
    ) mkString "\n")
  }
}
~~~

### Headers

[play.api.mvc.Request] contains two methods for inspecting HTTP headers:

 - the `headers` method returns a [play.api.mvc.Headers] object for inspecting general headers;
 - and `cookies` method returns a [play.api.mvc.Cookies] object for inspecting the `Cookies` header.

The APIs take care of common scenarios: missing headers, upper- and lower-case names, and so on. Here is a synopsis:

~~~ scala
object RequestDemo extends Controller {
  def headers = Action { request =>
    val headers: Headers = request.headers
    val ucType: Option[String] = headers.get("Content-Type")
    val lcType: Option[String] = headers.get("content-type")

    val cookies: Cookies = request.cookies
    val cookie: Option[Cookie] = cookies.get("DemoCookie")
    val value: Option[String] = cookie.map(_.value)

    Ok(Seq(
      s"Headers: $headers",
      s"Content-Type: $ucType",
      s"content-type: $lcType",
      s"Cookies: $cookies",
      s"Cookie value: $value"
    ) mkString "\n")
  }
}
~~~

[play.api.mvc.Request]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Request
[play.api.mvc.Headers]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Headers
[play.api.mvc.Cookies]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Cookies

<h3 id="bodies">Request Bodies</h3>

Up to this point we have been eliding an important implementation detail: [play.api.mvc.Request] is actually a *generic* type, `Request[A]`.

The type parameter `A` indicates the *type* of the request body. Play contains an number of built-in *body parsers* for handling common types of request. These parsers conveniently type values for further processing in Scala.

This begs a question: what type does `request.body` return in the examples we have seen so far? We haven't indicated the type of body we are expecting anywhere in our code. Play *cannot* know the content-type of a future request at compile, so how is this handled?

The answer is quite clever: by default our actions accept an argument of type `Request[AnyContent]`. [play.api.mvc.AnyContent] is Play's way of allowing us to choose how the request should be parsed -- it contains methods to parse the body in any of the formats discussed. Each method returns `None` if the request is empty or of of the wrong `Content-Type`:

|--------------------------------+---------------------------------------------------------------------|
| Method of `AnyContent`         | Return type                        | Works on `Content-Type`        |
|--------------------------------+------------------------------------+--------------------------------|
| `asText`                       | `Option[String]`                   | `text/plain`                   |
| `asFormUrlEncoded`             | `Option[Map[String, Seq[String]]]` | `application/form-url-encoded` |
| `asMultipartFormData`          | `Option[MultipartFormData]`        | `multipart/form-data`          |
| `asJson`                       | `Option[JsValue]`                  | `application/json`             |
| `asXml`                        | `Option[NodeSeq]`                  | `application/xml`              |
| `asRaw`                        | `Option[RawBuffer]`                | any                            |
|======================================================================================================|
{: .table .table-bordered .table-responsive }

[play.api.mvc.AnyContent]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.AnyContent
[play.api.mvc.MultipartFormData]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.MultipartFormData
[play.api.libs.json.JsValue]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.JsValue
[scala.xml.NodeSeq]: https://github.com/scala/scala-xml/blob/master/src/main/scala/scala/xml/NodeSeq.scala
[play.api.mvc.RawBuffer]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.RawBuffer

<div class="callout callout-warning">
#### Advanced: Custom Body Parsers

The `AnyContent` mechanism is a convenient way to parse request bodies in a type-safe fashion. However, it suffers from two drawbacks:

 - it only caters for a fixed set of common data types;
 - with the exception of multipart form data, requests must be read entirely into memory before parsing.

If the situation demands it, we can implement our own instances of [play.api.mvc.BodyParser] and use them in our actions as follows:

~~~ scala
object myDataParser new BodyParser[MyData] {
  // ...
}

def action = Action(myDataParser) { request: Request[MyData] =>
  val body: MyData = request.body
  // ...
}
~~~

For more information see Play's [documentation on body parsers].
</div>

[play.api.mvc.BodyParser]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.BodyParser
[documentation on body parsers]: https://www.playframework.com/documentation/2.3.x/ScalaBodyParsers

## Take Home Points

Incoming web requests are represented by objects of type `Request[A]`.

`Requests` contain methods to access all parts of the HTTP request: URI, request parameters, headers, cookies, and so on.

The type parameter on `Request[A]` refers to the type of the request body. This defaults to a type `AnyContent`, which contains methods to read the request body in a variety of content types.

Reading the body may succeed or fail depending on whether the content type matches the type we expect. The various `body.asFoo` methods return `Options` to force us to deal with the possibility of failure.
