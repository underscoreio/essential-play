---
layout: page
title: Constructing Results
---

# Constructing Results

The previous section dealt with the first stage of handling an HTTP request: parsing the request and extracting useful Scala data from it. This section discusses the complimentary process of converting Scala data back into a result to send back to the client.

## Setting The Status Code

We can construct results using a set of convenient factory objects defined in the [play.api.mvc.Results] trait, of which [play.api.mvc.Controller] is a subtype:

|----------------------------+-----------------------------------------|
| Constructur                | HTTP status code                        |
|----------------------------+-----------------------------------------|
| `Ok`                       | 200 Ok                                  |
| `NotFound`                 | 404 Not Found                           |
| `InternalServerError`      | 500 Internal Server Error               |
| `Unauthorized`             | 401 Unauthorized                        |
| `Status(number)`           | `number` (an `Int`) -- anything we want |
|======================================================================|
{: .table .table-bordered .table-responsive }

Each of the expressions in the table above creates an empty [play.api.mvc.Result] with a specified status code by no content. We can add content in a variety of ways.

[play.api.mvc.Results]:    https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Results
[play.api.mvc.Controller]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Controller
[play.api.mvc.Result]:     https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Result

## Adding Content

The usual way of adding content is to call the `apply` method. This sets both the content and content type of the result. For example, `Ok("Hello world!")` creates a 200 response of type `text/plain` containing the text *Hello world!*.

The `apply` method accepts arguments of a similar set of types described in *Request Bodies* in the previous section. Here are the most important ones:

|---------------------------------------------------------+------------------------------------------------------|
| Argument type to `apply`                                | Resulting `Content-Type`                             |
|---------------------------------------------------------+------------------------------------------------------|
| `String`                                                | `text/plain`                                         |
| `JsValue`                                               | `application/json`                                   |
| `NodeSeq`                                               | `application/xml`                                    |
| [play.twirl.api.Content] -- output of a [play template] | appropriate content type for the template[^template] |
|=========================================================+======================================================|
{: .table .table-bordered .table-responsive }

[play.twirl.api.Content]: https://github.com/playframework/twirl/blob/master/api/src/main/scala/play/twirl/api/Content.scala
[play template]:          https://www.playframework.com/documentation/2.3.x/ScalaTemplates

[^template]: As this course is primarily about web *services*, we won't cover Play templates here. See the linked documentation for more information.

<div class="callout callout-warning">
#### Advanced: Custom Result Types

The `apply` methods used to add content to results actually accept two parameters -- the content to add to the result and an implicit [play.api.http.Writeable] that specifies how to serialize that content:

~~~ scala
def apply[C](content: C)(implicit writeable: Writeable[C]): Result
~~~

We can add support for our own result types by implementing a custom [play.api.http.Writeable] for the given type and making it available in implicit score. Here's an example:

~~~ scala
implicit object MyDataWriteable extends Writeable[MyData] {
  // ...
}

def action = Action { request =>
  val data: MyData = // ...

  Ok(data) // Scala implicitly inserts MyDataWriteable as a second parameter
}
~~~

[play.api.http.Writeable]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.http.Writeable
</div>

## Tweaking the Result

Once we have created a result, we have access to a variety of methods to tweak its contents:

 - we can change the `Content-Type` using the `as` method;
 - we can add and/or alter HTTP headers using `withHeaders`;
 - we can add and/or alter cookies using `withCookies`.

Here's a short example:

~~~ scala
Ok("KTHXBAI").as("text/lolspeak").withHeaders(...).withCookies(...) // etc...
~~~

The API documentation for [play.api.mvc.Result] contains all of the necessary details.

[play.api.mvc.Result]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Result

## Take Home Points

Play actions return instances of [play.api.mvs.Result].

`Results` are created using factory objects defined in [play.api.mvs.Results], which is inherited by [play.api.mvc.Controller].

We can populate a `Result` with any data for which we have an implicit instance of [play.api.http.Writeable]. Play provides default instances for `String` (plain text), `JsValue` (JSON), `NodeSeq` (XML), and [play.twirl.api.Content] (output from Play templates).

`Result` contains methods for adding further parameters such as headers and cookies.

[play.api.mvc.Results]:    https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Results
[play.api.mvc.Controller]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Controller
[play.api.mvc.Result]:     https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.mvc.Result
[play.api.http.Writeable]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.http.Writeable
[play.twirl.api.Content]:  https://www.playframework.com/documentation/2.3.x/ScalaTemplates