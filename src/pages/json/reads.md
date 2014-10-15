---
layout: page
title: Reading JSON
---

# Reading JSON

In the previous section we saw how to use the `Writes` type class and the `Json.toJson` method to convert objects from our domain model to JSON to embed them in a `Result`. In this section we will look at the opposite process -- reading JSON data from a `Request` and converting it to domain objects.

## Meet *Reads*

Play defines a `Reads` type class, `Json.reads` macro, and `Json.toJson` method that are analogous to `Writes`, `Json.writes` and `Json.toJson`. Here's a synopsis:

~~~ scala
case class Address(number: Int, street: String)
case class Person(name: String, address: Address)

implicit val addressReads = Json.reads[Address]
implicit val personReads  = Json.reads[Person]

// This compiles because we have a `Reads[Address]` in scope:
Json.fromJson(Json.obj("number" -> 29, "street" -> "Acacia Road"))

// This compiles because we have a `Reads[Person]` in scope:
Json.fromJson(Json.obj(
  "name"    -> "Eric Wimp",
  "address" -> Json.obj
    "name"   -> 29,
    "street" -> "Acacia Road"
  )
))
~~~

So far so good -- reading JSON data is at least superficially similar to writing it.

## Accepting failure

The main difference between reading and writing as operations is that reading can *fail*. `Reads` handles this by wrapping return values in an `Either`-like data structure called a [play.api.json.libs.JsResult] that represents the possibilities of success or failure.

`JsResult` has two subtypes: [play.api.json.libs.JsSuccess] represents a successful result, and [play.api.libs.json.JsError] represents a failure. `JsError` contains data on the location and nature of every problem encountered attempting to read the JSON:

~~~ scala
// Attempt to read JSON as an Address -- might succeed or fail:
val result: JsResult[Address] = addressReads.reads(json)

// Match on the result to see if the read was successful:
result match {
  case JsSuccess(address, _) =>
    println("The JSON was good: " + address)

  case JsError(errors) =>
    println("The JSON was bad:")
    for {
      (path, errors) <- pathsAndErrors
      error <- errors
    } println(s"Error at $path: $pathError")
}
~~~

We will see more about paths and parse errors later.

[play.api.libs.json.Reads]:    https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Reads
[play.api.libs.json.Writes]:   https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Writes
[play.api.libs.json.Format]:   https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Format
[play.api.libs.json.JsResult]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.JsResult

<div class="callout callout-info">
### *Reads* Best Practices

We can use Scala's type system to our advantage, using it eliminate many kinds of errors from our applications. For this reason it is sensible to extract the incoming JSON from a `Request` and convert it to a sane, well-typed data model as soon as we can. If the read fails, we typically returns a *400 Bad Request* `Result` to the client indicating any errors encountered.

It is straightforward to write a method that accepts a `JsError` and turns it into a `Result`, and then use that method when parsing a request:

~~~ scala
/**
 * Traverse the errors in `err` and return a BadRequest` result
 * containing appropriate JSON to send to the client.
 */
def jsErrorResponse(err: JsError): Result = {
  // ...
}

/**
 * Extract the JSON body from `request`, read it as type `A`
 * and then pass it to `func`.
 *
 * If anything goes wrong, immediately return a *400 Bad Request* result
 * describing the failure.
 */
def withRequestJson[A](request: Request[AnyContent])(func: A => Result)
    (implicit reads: Reads[A]): Result = {
  request.body.asJson match {
    case Some(body) =>
      Json.fromJson(body) match {
        case success: JsSuccess[A] => func(success.value)
        case error: JsError        => jsErrorResponse(error)
      }
    }
  }
}

// Example use case:
def index = Action { request =>
  withRequestJson[Person](request) { person =>
    Ok(person.toString)
  }
}
~~~
</div>

## Take home points

We convert Scala data to JSON using instances of [play.api.libs.json.Reads].

Play provides a convenient macro, `Json.reads`, to define a `Reads` for any case class.

When reading JSON data we have to deal with the possibility of formatting errors. Instances of `Reads[A]` return values of type `JsResult[A]` that either contain the successful result or the read, or a machine-readable list of read errors.

`Reads` is a *type class* used by the `Json.fromJson` method. The recommended recipe for its use is as follows:

 1. Define an `implicit` instances of `Reads[A]`.
 2. Place the instance in the companion object for `A`, or in a separate object containing relevant `Implicits`.
 3. Read a call `Json.fromJson(myValue)` ensuring the implicit `Reads` is in scope.
