## Parsing Requests

So far we have seen how to create `Actions` and map them to URIs using *routes*. In the rest of this chapter we will take a closer look at the code we write in the actions themselves.

The first job of any `Action` is to extract data from the HTTP request and turn it into well-typed, validated Scala values. We have already seen how routes allow us to extract information from the URI. In this section we will see the other tools Play provides for the rest of the `Request`.

### Request Bodies {#bodies}

The most important source of request data comes from the *body*. Clients can `POST` or `PUT` data in a huge range of formats, the most common being JSON, XML, and form data. Our first task is to identify the content type and parse the body.

Confession time. Up to this point we've been telling a white lie about `Request`---it is actually a generic type, `Request[A]`. The parameter `A` indicates the type of body, which we can retrieve via the `body` method:

~~~ scala
def index = Action { request =>
  val body: ??? = request.body
  // ... what type is `body`? ...
}
~~~

Play contains an number of *body parsers* that we can use to parse the request, returning a `body` of an appropriate Scala type.

So what type does `request.body` return in the examples we've seen so far? We haven't chosen a body parser, nor have we indicated the type of body anywhere in our code. Play *cannot* know the `Content-Type` of a request at compile time, so how is this handled? The answer is quite clever---by default our actions handle requests of type `Request[AnyContent]`.

[`play.api.mvc.AnyContent`] allows us to *choose* how to read the request in our `Action` code. It reads the request body into a buffer and provides methods to parse it in a handful of common formats. Each method has an `Optional` result, returning `None` if the request is empty or has the wrong `Content-Type`:

:Body parser return types

----------------------------------------------------------------------------------------------------
Method of `AnyContent`          Request content type            Return type
------------------------------- ------------------------------- ------------------------------------
`asText`                        `text/plain`                    `Option[String]`

`asFormUrlEncoded`              `application/form-url-encoded`  `Option[Map[String, Seq[String]]]`

`asMultipartFormData`           `multipart/form-data`           `Option[MultipartFormData]`

`asJson`                        `application/json`              `Option[JsValue]`

`asXml`                         `application/xml`               `Option[NodeSeq]`

`asRaw`                         any                             `Option[RawBuffer]`
----------------------------------------------------------------------------------------------------

<div class="callout callout-warning">
*Custom Body Parsers*

`AnyContent` is a convenient way to parse common types of request bodies. However, it suffers from two drawbacks:

 - it only caters for a fixed set of common data types;
 - with the exception of multipart form data, requests must be read entirely into memory before parsing.

If we are certain about the data type we want in a particular `Action`, we can specify a *body parser* to restrict it to a specific type. Play returns a *400 Bad Request* response to the client if it cannot parse the request as the relevant type:

~~~ scala
import play.api.mvc.BodyParsers.parse

def index = Action(parse.json) { request =>
  val body: JsValue = request.body
  // ...
}
~~~

If the situation demands, we can even implement our own *custom body parsers* to parse exotic formats:

~~~ scala
object myDataParser new BodyParser[MyData] {
  // ...
}

def action = Action(myDataParser) { request =>
  val body: MyData = request.body
  // ...
}
~~~

See Play's [documentation on body parsers](docs-body-parsers) for more information.
</div>

### Headers and Cookies

`Request` contains two methods for inspecting HTTP headers:

 - the `headers` method returns a [`play.api.mvc.Headers`] object for inspecting general headers;
 - and `cookies` method returns a [`play.api.mvc.Cookies`] object for inspecting the `Cookies` header.

These take care of common error scenarios: missing headers, upper- and lower-case names, and so on. Values are treated as `Strings` throughout---Play doesn't attempt to parse headers as dedicated Scala types. Here is a synopsis:

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

Note that the `Headers.get` method is case insensitive---we can grab the `Content-Type` using `headers.get("Content-Type")` or `headers.get("content-type")`. Cookie names, on the other hand, are case sensitive. Make sure you define your cookie names as constants to avoid case errors!

### Methods and URIs

Routes are the recommended way of extracting information from a method or URI. However, the `Request` object also provides methods that are of occasional use:

~~~ scala
// The HTTP method ("GET", "POST", etc):
val method: String = request.method

// The URI, including path and query string:
val uri: String = request.uri

// The path of the URI, without the query string:
val path: String = request.path

// The query string, split into name/value pairs:
val query: Map[String, Seq[String]] = request.queryString
~~~

### Take Home Points

Incoming web requests are represented by objects of type `Request[A]`. The type parameter `A` indicates the type of the request body.

By default, Play represents bodies using a type called `AnyContent` that allows us to parse bodies a set of common data types.

Reading the body may succeed or fail depending on whether the content type matches the type we expect. The various `body.asX` methods such as `body.asJson` return `Options` to force us to deal with the possibility of failure.

`Request` also contains methods to access HTTP headers, cookies, and various parts of the HTTP method and URI.
