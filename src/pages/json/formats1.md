---
layout: page
title: Reading and Writing JSON (Part 1)
---

# Reading and Writing JSON (Part 1)

In a typical web service, most of our business logic will involve operations on a *domain model* consisting of sealed traits, case classes, and case objects.

In the controller layer of our service we implement a suite of *conversions* between our domain model and `JsValue`, giving us the ability to send and receive domain objects in JSON formats.

This section introduces the basic mechanisms for implementing these conversions. The next section goes into more depth about specific use cases.

## Reads and Writes

We implement these conversions using two data types from the Play API:

 - we convert JSON data to Scala data using instances of trait [play.api.libs.json.Reads];
 - we convert Scala data to JSON data using instances of trait [play.api.libs.json.Writes].

Play provides a trivial mechanism to define `Reads` and `Writes` for any case class:

~~~ scala
case class Address(number: Int, street: String)

val addressReads:  Reads[Address]  = Json.reads[Address]
val addressWrites: Writes[Address] = Json.writes[Address]
~~~

### Using Writes

We can use `addressWrites` to convert an `Address` to a `JsValue`:

~~~ scala
// Create an address:
val address = Address(29, "Acacia Road")

// Convert it to JSON:
val json: JsValue = addressWrites.writes(address)
~~~

and use the `JsValue` to construct a JSON `Result` to pass back to the client:

~~~ scala
def index = Action { request =>
  val address = Address(29, "Acacia Road")
  val json = addressWrites.writes(address)
  Ok(json)
}
~~~

### Using Reads

We can use `addressReads` to convert a `JsValue` into an `Address`.

We can't tell at compile time whether any given conversion will succeed or fail, so `Reads` is built to anticipate failure. Rather than returning a plain `Address`, `addressReads` returns a [play.api.libs.json.JsResult], which is an `Either`-like data structure representing a success *or* a failure:

~~~ scala
// Attempt to read JSON as an Address -- might succeed or fail:
val result: JsResult[Address] = addressReads.reads(json)
~~~

We can match on the `JsResult` to see whether the read succeeded:

~~~ scala
// Match on the result to see if the read was successful:
result match {
  case JsSuccess(address) => println("The address is " + address)
  case JsErrors(errors)   => println("Could not read the JSON: " + errors)
}
~~~

[play.api.libs.json.Reads]:    https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Reads
[play.api.libs.json.Writes]:   https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Writes
[play.api.libs.json.Format]:   https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.Format
[play.api.libs.json.JsResult]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.json.JsResult

### Formats

In addition to `Reads` and `Writes`, Play defines a third trait, [play.api.libs.json.Format], that subsumes both sets of functionality:

~~~ scala
trait Format[-A] extends Reads[A] with Writes[A]
~~~

`Formats` are a convenience that allow us to define reading and writing in one step:

~~~ scala
val addressFormat: Format[Address] = Json.format[Address]
val addressJson: JsValue = addressFormat.writes(address)
val addressResult: JsResult[Address] = addressFormat.reads(address)
~~~

## Implicit Formats

We have seen how to declare `Reads`, `Writes` and `Formats` for a simple case class. What about a more complicated example?

Let's try to define `Formats` for a nested data structure:

~~~ scala
case class Address(number: Int, street: String)
case class Person(name: String, address: Address)

val addressFormat = Json.format[Address]
val personFormat  = Json.format[Person] // will not compile
~~~

If we try to compile this code, we will an error on the the last line:

~~~
error: No implicit format for Address available.
~~~

This is because `Json.reads`, `Json.writes` and `Json.format` are defined recursively in terms of the fields of the type parmeter:

 - we can create a `Format` for `Address` if we have formats for `Int` and `String`;
 - we can create a `Format` for `Person` if we have formats for `String` and `Address`.

`Reads`, `Writes` and `Formats` are looked up by type using Scala's implicit resolution mechanism. There are built-in implicit values for `Int` and `String` as we can see here:

~~~ scala
import play.api.libs.json._

implicitly[Writes[String]].writes("Hello!") // => JsString("Hello!")
~~~

In order to create a `Format[Person]`, we need to make our `Format[Address]` available to the implicit mechanism. In this case, inserting the keyword `implicit` does the trick:

~~~ scala
implicit val addressFormat = Json.format[Address]

val personFormat = Json.format[Person] // compiles
~~~

As a final bonus, Play provides two top-level methods that can convert between any Scala type and `JsValue` as long as we have an implicit `Reads` or `Writes` in scope:

~~~ scala
val json   = Json.toJson(address)  // locates a `Writes[Address]` implicitly

val person = Json.fromJson[Person] // locates a `Reads[Person]` implicitly
~~~~

It therefore benefits to define `personFormat` as an implicit value as well as `addressFormat`, allowing us to use the same methods to read/write values of either type:

~~~ scala
implicit val addressFormat = Json.format[Address]
implicit val personFormat  = Json.format[Person]

val json: JsValue = Json.toJson(Person("Eric Wimp", Address(29, "Acacia Road")))

val result: JsResult[Person] = Json.fromJson[Person](json)
~~~

## Take Home Points

TODO