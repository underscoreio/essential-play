## Constructing Results

In the previous section we saw how to extract well-typed Scala values from an incoming request. This should always be the first step in any `Action`. If we tame incoming data using the type system, we remove a lot of complexity and possibility of error from our business logic.

Once we have finished our business logic, the final step of any `Action` is to convert the result into a `Result` object. In this section we will see how to create `Results`, populate them with content, and add headers and cookies.

### Setting The Status Code

Play provides a convenient set of factory objects for creating `Results`. These are defined in the [`play.api.mvc.Results`] trait and inherited by [`play.api.mvc.Controller`]

:Result codes

-------------------------------------------------------------------
Constructor                 HTTP status code
--------------------------- ---------------------------------------
`Ok`                        200 Ok

`NotFound`                  404 Not Found

`InternalServerError`       500 Internal Server Error

`Unauthorized`              401 Unauthorized

`Status(number)`            `number` (an `Int`) -- anything we want
-------------------------------------------------------------------

Each factory has an `apply` method that creates a `Result` with a different HTTP status code. `Ok.apply` creates 200 responses, `NotFound.apply` creates 404 responses, and so on. The `Status` object is different: it allows us to specify the status as an `Int` parameter. The end result in each case is a `Result` that we can return from our `Action`:

~~~ scala
val result1: Result = Ok("Success!")
val result2: Result = NotFound("Is it behind the fridge?")
val result3: Result = Status(401)("Access denied, Dave.")
~~~

### Adding Content

Play adds `Content-Type` headers to our `Results` based on the type of data we provide. In the examples above we provide `String` data. creating three results of `Content-Type: text/plain`.

We can create `Results` using values of other Scala types, provided Play understands how to serialize them. Play even sets the `Content-Type` header for us as a convenience. Here are some examples:

:Result *Content-Types*

--------------------------------------------------------------------------------------------
Using this Scala type...                                         Yields this result type...
---------------------------------------------------------------- ---------------------------
`String`                                                         `text/plain`

[`play.twirl.api.Html`] (see [Chapter 3](#chapter-html))         `text/html`

[`play.api.libs.json.JsValue`] (see [Chapter 4](#chapter-json))  `application/json`

`scala.xml.NodeSeq`                                              `application/xml`

`Array[Byte]`                                                    `application/octet-stream`
--------------------------------------------------------------------------------------------

The process of creating a `Result` is type-safe -- Play determines the method of serialization based on the *type* we give it. If it understands what to do with our data, we get a working `Result`. If it doesn't understand the type we give it, we get a compilation error. As a consequence, the final steps in an `Action` tend to be:

 1. convert the result of our business logic to a type Play can serialize:
    - HTML using a Twirl template, or;
    - a `JsValue` to return the data as JSON, or;
    - a Scala `NodeSeq` to return the data as XML, or;
    - a `String` or `Array[Byte]`.

 2. use the serializable data to create a `Result`;

 3. tweak HTTP headers and so on;

 4. return the `Result`.

<div class="callout callout-warning">
*Custom Result Types*

Play understands a limited set of result content types out-of-the-box. We can add support for our own types by defining instances of the [`play.api.http.Writeable`] type class. See the Scaladocs for more information:

~~~ scala
// We have a custom library for manipulating iCal calendar files:
case class ICal(/* ... */)

// We implement an implicit `Writeable[ICal]`:
implicit object ICalWriteable extends Writeable[ICal] {
  // ...
}

// Now our actions can serialize `ICal` results:
def action = Action { request =>
  val myCal: ICal = ICal(/* ... */)

  Ok(myCal) // Play uses `ICalWriteable` to serialize `myCal`
}
~~~

The intention of `Writeable` is to support general data formats. We wouldn't create a `Writeable` to serialize a specific class from our business model, for example, but we might write one to support a format such as XLS, Markdown, or iCal.

</div>

### Tweaking the Result

Once we have created a `Result`, we have access to a variety of methods to alter its contents. The API documentation for [`play.api.mvc.Result`] documents the options available:

 - we can change the `Content-Type` header (without changing the content) using the `as` method;
 - we can add and/or alter HTTP headers using `withHeaders`;
 - we can add and/or alter cookies using `withCookies`.

These methods can be chained, allowing us to create the `Result`, tweak it, and return it in a single expression:

~~~ scala
def ohai = Action { request =>
  Ok("OHAI").
    as("text/lolspeak").
    withHeaders(/* ... */).
    withCookies(/* ... */)
}
~~~

### Take Home Points

The final step of an `Actions` is to create and return a [`play.api.mvc.Result`].

We create `Results` using factory objects provided by [`play.api.mvc.Controller`]. Each factory creates `Results` with a specific HTTP status code.

We can `Results` with a variety of data types. Play provides built-in support for `String`, `JsValue`, `NodeSeq`, and `Html`. We can add our own data types by writing instances of the [`play.api.http.Writeable`] type class.

Once we have created a `Result`, we can tweak headers and cookies before returning it.
