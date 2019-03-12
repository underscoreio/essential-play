## Constructing Results

In the previous section we saw how to extract
well-typed Scala values from an incoming request.
This should always be the first step in any `Action`.
If we tame incoming data using the type system,
we remove a lot of complexity and possibility of error from our business logic.

Once we have finished processing the request,
the final step of any `Action` is to convert the result into a `Result`.
In this section we will see how to create `Results`,
populate them with content, and add headers and cookies.


### Setting The Status Code

Play provides a convenient set of factory objects for creating `Results`.
These are defined in the [`play.api.mvc.Results`] trait
and inherited by [`play.api.mvc.Controller`]

:Result codes

-------------------------------------------------------------------
Constructor                 HTTP status code
--------------------------- ---------------------------------------
`Ok`                        200 Ok

`NotFound`                  404 Not Found

`InternalServerError`       500 Internal Server Error

`Unauthorized`              401 Unauthorized

`Status(number)`            `number` (an `Int`)---anything we want
-------------------------------------------------------------------

Each factory has an `apply` method that creates a `Result`
with a different HTTP status code.
`Ok.apply` creates 200 responses,
`NotFound.apply` creates 404 responses, and so on.
The `Status` object is different:
it allows us to specify the status as an `Int` parameter.
The end result in each case is a `Result` that we can return from our `Action`:

~~~ scala
val result1: Result = Ok("Success!")
val result2: Result = NotFound("Is it behind the fridge?")
val result3: Result = Status(401)("Access denied, Dave.")
~~~


### Adding Content

Play adds `Content-Type` headers to our `Results`
based on the type of data we provide.
In the examples above we provide `String` data
creating three results of `Content-Type: text/plain`.

We can create `Results` using values of other Scala types,
provided Play understands how to serialize them.
Play even sets the `Content-Type` header for us as a convenience.
Here are some examples:

:Result *Content-Types*

-------------------------------------------------------------
Using this Scala type...          Yields this result type...
--------------------------------- ---------------------------
`String`                          `text/plain`

[`play.twirl.api.Html`]           `text/html`
(see [Chapter 2](#chapter-html))

[`play.api.libs.json.JsValue`]    `application/json`
(see [Chapter 3](#chapter-json))

`scala.xml.NodeSeq`               `application/xml`

`Array[Byte]`                     `application/octet-stream`
-------------------------------------------------------------

The process of creating a `Result` is type-safe.
Play determines the method of serialization based on the *type* we give it.
If it understands what to do with our data, we get a working `Result`.
If it doesn't understand the type we give it, we get a compilation error.
As a consequence the final steps in an `Action` tend to be as follows:

 1. Convert the result of action to a type that Play can serialize:
    - HTML using a Twirl template, or;
    - a `JsValue` to return the data as JSON, or;
    - a Scala `NodeSeq` to return the data as XML, or;
    - a `String` or `Array[Byte]`.

 2. Use the serializable data to create a `Result`.

 3. Tweak HTTP headers and so on.

 4. Return the `Result`.

<div class="callout callout-warning">
*Custom Result Types*

Play understands a limited set of result content types out-of-the-box.
We can add support for our own types
by defining instances of the [`play.api.http.Writeable`] type class.
See the Scaladocs for more information:

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

The intention of `Writeable` is to support general data formats.
We wouldn't create a `Writeable` to serialize a specific class
from our business model, for example,
but we might write one to support a format such as XLS, Markdown, or iCal.

</div>


### Tweaking the Result

Once we have created a `Result`,
we have access to a variety of methods to alter its contents.
The API documentation for [`play.api.mvc.Result`] shows this:

 - we can change the `Content-Type` header (without changing the content)
   using the `as` method;

 - we can add and/or alter HTTP headers using `withHeaders`;

 - we can add and/or alter cookies using `withCookies`.

These methods can be chained, allowing us to
create the `Result`, tweak it, and return it in a single expression:

~~~ scala
def ohai = Action { request =>
  Ok("OHAI").
    as("text/lolspeak").
    withHeaders(
      "Cache-Control" -> "no-cache, no-store, must-revalidate",
      "Pragma"        -> "no-cache",
      "Expires"       -> "0",
      // etc...
    ).
    withCookies(
      Cookie(name = "DemoCookie", value = "DemoCookieValue"),
      Cookie(name = "OtherCookie", value = "OtherCookieValue"),
      // etc...
    )
}
~~~


### Take Home Points

The final step of an `Actions` is
to create and return a [`play.api.mvc.Result`].

We create `Results` using factory objects provided
by [`play.api.mvc.Controller`].
Each factory creates `Results` with a specific HTTP status code.

We can `Results` with a variety of data types.
Play provides built-in support for
`String`, `JsValue`, `NodeSeq`, and `Html`.
We can add our own data types
by writing instances of the [`play.api.http.Writeable`] type class.

Once we have created a `Result`,
we can tweak headers and cookies before returning it.


### Exercise: Comma Separated Values

The `chapter2-csv` directory in the exercises contains
an unfinished Play application for
converting various data formats to CSV.
Complete the application by filling in the missing action
in `app/controllers/CsvController.scala`.

The action is more complicated than in previous exercises.
It must accept data POSTed to it by the client and convert it to CSV
using the relevant helper method from `CsvHelpers`.

We have included several files to help you test the code:
`test.formdata` and `test.tsv` are text files containing test data,
and the various `run-` shell scripts make calls to `curl`
with the correct command line parameters.

Your code should behave as follows:

 -  Form data (content type `application/x-url-form-url-encoded`) should
    be converted to CSV in columnar orientation and returned with `text/csv`
    content type:

    ~~~ bash
    bash$ ./run-form-data-test.sh
    # This script submits `test.formdata` with content type
    # `application/x-url-form-url-encoded`.
    #
    # Curl prints HTTP data from request and response including...
    < HTTP/1.1 200 OK
    < Content-Type: text/csv

    A,B,C
    100,200,300
    110,220,330
    111,222,
    ~~~

 -  Post data of type `text/plain` or `text/tsv` should be treated as tab
    separated values. The tabs should be replaced with commas and the result
    returned with content type `text/csv`:

    ~~~ bash
    bash$ ./run-tsv-test.sh
    # This script submits `test.tsv` with content type `text/tsv`.
    #
    # Curl prints HTTP data from request and response including...
    < HTTP/1.1 200 OK
    < Content-Type: text/csv

    A,B,C
    1,2,3

    bash$ ./run-plain-text-test.sh
    # This script submits `test.tsv` with content type `text/plain`.
    #
    # Curl prints HTTP data from request and response including...
    < HTTP/1.1 200 OK
    < Content-Type: text/csv

    A,B,C
    1,2,3
    ~~~

 -  Any other type of post data should yield a 400 response with a sensible
    error message:

    ~~~ bash
    bash$ ./run-bad-request-test.sh
    # This script submits `test.tsv` with content type `foo/bar`.
    #
    # Curl prints HTTP data from request and response including...
    < HTTP/1.1 400 Bad Request
    < Content-Type: text/plain

    Expected application/x-www-form-url-encoded, text/tsv, or text/plain
    ~~~

Answer the following question when you are done:

Are your handlers for `text/plain` and `text/tsv` interchangeable?
What happens when you remove one of the handlers
and submit a file of the corresponding type?
Does play compensate by running the other handler?

<div class="solution">
There are several parts to this solution:
create handler functions for the various content types,
ensure that the results have the correct status code and content type,
and chain the handlers together to implement our `Action`.
We will address each part in turn.

First let's create handlers for each content type.
We have three types to consider:
`text/plain` , `text/tsv` , and `application/x-www-form-url-encoded`.
Play has built-in body parsers for the first two.
The methods in `CsvHelpers` do most of the rest of the work:

~~~ scala
def formDataResult(request: Request[AnyContent]): Option[Result] =
  request.body.asFormUrlEncoded map formDataToCsv map csvResult

def plainTextResult(request: Request[AnyContent]): Option[Result] =
  request.body.asText map tsvToCsv map csvResult
~~~

The `text/tsv` conten type is trickier, however.
We can't use `request.body.asText`---it returns `None`
because Play assumes the request content is binary.
We have to use `request.body.asRaw` to get a `RawBuffer`,
extract the `Array[Byte]` within, and create a `String`:

~~~ scala
def rawBufferResult(request: Request[AnyContent]): Option[Result] =
  request.contentType flatMap {
    case "text/tsv" => request.body.asRaw map rawBufferToCsv map csvResult
    case _          => None
  }
~~~

Note the pass-through clause for content types other than `"text/tsv"`.
We have no control over the types of data the client may send our way,
so we always have to provide a mechanism for dealing with the unexpected.

Also note that the conversion method in `rawBufferToCsv` assumes
unicode character encoding---make sure you check for other encodings
if you write code like this in your production applications!

Each of the handler functions uses a common `csvResult` method
to convert the `String` CSV data to a `Result`
with the correct status code and content type:

~~~ scala
def csvResult(csvData: String): Result =
  Ok(csvData).withHeaders("Content-Type" -> "text/csv")
~~~

We also need a handler for the case where
we don't know how to parse the request.
In this case we return a `BadRequest` result
with a content type of `"text/plain"`:

~~~ scala
val failResult: Result =
    BadRequest("Expected application/x-www-form-url-encoded, " +
               "text/tsv, or text/plain")
~~~

Finally, we need to put these pieces together.
Because each of our handlers returns an `Option[Result]`,
we can use the standard methods to chain them together:

~~~ scala
def toCsv = Action { request =>
  formDataResult(request) orElse
    plainTextResult(request) orElse
    rawBufferResult(request) getOrElse
    failResult
}
~~~

The answer to the question is as follows.
Although we are using `"text/plain"` and `"text/tsv"` interchangeably,
Play treats the two content types differently:

 -  `"text/plain"` is parsed as plain text.
    `request.body.asText` returns `Some` and
    `request.body.asRaw` returns `None`;

 -  `"text/tsv"` is parsed as binary data.
    `request.body.asText` returns `None` and
    `request.body.asRaw` returns `Some`.

In lieu of writing a custom `BodyParser` for `"text/tsv"` requests,
we have to work around Play's (understandable) misinterpretation of the format.
We read the data as a `RawBuffer` and convert it to a `String`.
The example code for doing this is error-prone
because it doesn't deal with character encodings correctly.
We would have to address this ourselves in a production application.
However, the example demonstrates the principle of dispatching
on content type and parsing the request appropriately.
</div>