---
layout: page
title: Reading JSON
---

## Reading JSON

In the previous section we saw how to use `Writes` and `Json.toJson` to convert domain objects to JSON. In this section we will look at the opposite process -- reading JSON data from a `Request` and converting it to domain objects.

### Meet *Reads*

We parse incoming JSON using instances of the [play.api.libs.json.Reads] trait. Play also defines a`Json.reads` macro and `Json.fromJson` method that compliment `Json.writes` and `Json.toJson`. Here's a synopsis:

~~~ scala
import play.api.libs.json._

case class Address(number: Int, street: String)
case class Person(name: String, address: Address)

implicit val addressReads = Json.reads[Address]
implicit val personReads  = Json.reads[Person]

// This compiles because we have a `Reads[Address]` in scope:
Json.fromJson[Address](Json.obj(
  "number" -> 29,
  "street" -> "Acacia Road"
))

// This compiles because we have a `Reads[Person]` in scope:
Json.fromJson[Person](Json.obj(
  "name"    -> "Eric Wimp",
  "address" -> Json.obj(
    "number" -> 29,
    "street" -> "Acacia Road"
  )
))
~~~

So far so good -- reading JSON data is at least superficially similar to writing it.

[play.api.libs.json.Reads]

### Embracing Failure

The main difference between reading and writing JSON is that reading can *fail*. `Reads` handles this by wrapping return values in an `Either`-like data structure called [play.api.libs.json.JsResult].

`JsResult[A]` has two subtypes:

 - [play.api.libs.json.JsSuccess] represents the result of a successful read;
 - [play.api.libs.json.JsError] represents the result of a failed read.

Like `Form`, `JsResult` has a `fold` method that allows us to branch based on the success/failure of a read:

~~~ scala
// Attempt to read JSON as an Address -- might succeed or fail:
val result: JsResult[Address] = addressReads.reads(json)

result.fold(
  errors  => println("The JSON was bad: "  + errors),
  address => println("The JSON was good: " + address)
)
~~~

We can equivalently use pattern matching to inspect the result:

~~~ scala
result match {
  case JsError(errors) =>
    println("The JSON was bad: " + errors)

  case JsSuccess(address, _) =>
    println("The JSON was good: " + address)
}
~~~

The `address` parameters in these examples are of type `Address`, while the `errors` parameters are sequences of structured error messages.

### Errors and *JsPaths*

The read errors in `JsError` have the type `Seq[(JsPath, Seq[ValidationError])]`:

 - each item is a pair of a `JsPath` representing a location in the JSON,
   and a `Seq[ValidationError]` representing the errors at that location;

 - each `ValidationError` contains a `String` error code and an optional list of arguments.

Here's an example:

~~~ scala
val result = Json.fromJson[Person](Json.obj(
  "address" -> Json.obj(
    "number" -> "29",
    "street" -> JsNull
  )
))

/*
result == JsError(List(
  ( JsPath \ "address" \ "number" , List(ValidationError("error.expected.jsnumber", Nil)) ),
  ( JsPath \ "address" \ "street" , List(ValidationError("error.expected.jsstring", Nil)) ),
  ( JsPath \ "name"               , List(ValidationError("error.path.missing",      Nil)) )
))
*/
~~~

The most interesting parts of the data are the `JsPaths` that describe locations of the errors. Each `JsPath` describes the sequence of field and array accessors required to locate a particular value in the JSON.

We build paths starting with the singleton object `JsPath`, representing an empty path. We can use the following methods to construct new paths by appending segments:

 - `\` appends a field accessor;
 - `apply` appends an array accessor.

The resulting path describes the location of a field or array item relative the the root of our JSON value. Here are some examples:

|--------------------------------------------------------------------------------------------------------------|
| Scala expression        | Javascript equivalent | Meaning                                                    |
|--------------------------------------------------------------------------------------------------------------|
| `JsPath`                | `root`                | The root JSON array or object                              |
| `JsPath \ "a"`          | `root.a`              | The field `a` in the root object                           |
| `JsPath(2)`             | `root[2]`             | The third item in the root array                           |
| `JsPath \ "a" \ "b"`    | `root.a.b`            | The field `b` in the field `a` in the root object          |
| `JsPath \ "a" apply 2`  | `root.a[2]`           | The third array item in the field `a` in the root object   |
|==============================================================================================================|
{: .table .table-bordered .table-responsive }

Obviously, different `JsPaths` impose implicit assumptions on the structure of the objects and arrays in our data. However, we can safely assume that the `JsPaths` in our errors point to valid locations in the data being parsed.

<div class="callout callout-info">
### Summary: *Reads* Best Practices

We can use Scala's type system to eliminate many sources of programmer error. It makes sense to parse incoming JSON as soon as possible using `Json.fromJson`, to convert it to well-typed data from our domain model.

If the read operation fails, the `JsPaths` in our error data indicate the locations of any read errors. We can use this information to send an informative *400 Bad Request* `Result` to the client:

~~~ scala
/**
 * Create a `JsArray` describing the errors in `err`.
 */
def errorJson(err: JsError): JsArray = {
  val fields = for {
    (path, errors) <- err.errors
  } yield {
    val name  = path.toJsonString
    val value = errors.map(error => JsString(error.message))
    (name, value)
  }

  JsObject(fields)
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
        case error: JsError        => BadRequest(errorJson(error))
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

### Take Home Points

We convert Scala data to JSON using instances of [play.api.libs.json.Reads].

Play provides a `Json.reads` macro and `Json.fromJson` method that mirror `Json.writes` and `Json.toJson`.

When reading JSON data we have to deal with the possible read errors. The `reads` method of `Reads[A]` returns values of type `JsResult[A]` to indicate success/failure.

`JsError` contains `ValidationError` objects for each read error, mapped against `JsPaths` representing the location of the errors in our JSON. We can use this data to report errors back to the client.
