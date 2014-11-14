---
layout: page
title: Modelling JSON
---

# Modelling JSON

Play models JSON data using instances of a sealed trait called [play.api.libs.json.JsValue]. There are five subtypes of `JsValue`, each representing one of the types in the [JSON specification]

~~~ scala
package play.api.libs.json

sealed trait JsValue
final case class JsObject(fields: Seq[(String, JsValue)]) exteds JsValue
final case class JsArray(values: Seq[JsValue]) extends JsValue
final case class JsString(value: String) extends JsValue
final case class JsNumber(value: Double) extends JsValue
final case class JsBoolean(value: Boolean) extends JsValue
final case object JsNull extends JsValue
~~~

Each of these types allows us to *wrap up* one or more Scala values to describe its representation in JSON. For example, the `String` `"Dave"` can be converted to JSON by wrapping it in a `JsString`. We have to implement mappings for more complex types ourselves.

`JsValues` can be converted to and from JSON strings, which can be passed around in `Requests` and `Results`. The typical lifecycle of a JSON HTTP request is therefore:

 - receive a `Request`;
 - extract its body as a `JsValue`;
 - convert the `JsValue` to a domain object
 - run our business logic;
 - convert the result of our business logic into a second `JsValue`;
 - wrap the `JsValue` in a `Result`.

This section describes how to construct, traverse, and deconstruct `JsValues` by hand, which is useful for ad hoc operations on JSON data. The next two sections describe how to create mappings between `JsValues` and domain objects, and use them to validate the JSON we receive in `Requests`.

# Constructing JSON Data

Using `JsValue` and its subtypes, we can represent any fragment of JSON data as a tree of Scala values. For example:

<div class="row">
<div class="col-sm-6">
**JSON Data**

~~~ json
{
  "name": "Dave",
  "age": 35,
  "likes": [
    "Scala",
    "Coffee",
    "Pianos"
  ],
  "dislikes": null
}
~~~
</div>
<div class="col-sm-6">
**Equivalent `JsValue`**

~~~ scala
JsObject(Seq(
  "name" -> JsString("Dave"),
  "age" -> JsNumber(35.0),
  "likes" -> JsArray(Seq(
    JsString("Scala"),
    JsString("Coffee"),
    JsString("Pianos")
  )),
  "dislikes" -> JsNull
))
~~~
</div>
</div>

Having to write `JsString` and `JsNumber` around every literal value is inconvenient. Fortunately, play also provides a simple DSL for creating JSON values via two helper methods on the [play.api.libs.json.Json] object:

 - `Json.arr(...)` takes an arbitrary number of parameters, each of which must be of a type that can automatically be converted to a `JsValue`. We'll see how this automatic conversion works in the next section. For now, assume we can rely on the following:
    - `Strings` are converted to `JsStrings`;
    - `Ints` and `Doubles` are converted to `JsNumbers`;
    - `Booleans` are converted to `JsBooleans`.

 - `Json.obj(...)` takes an arbitrary number of parameters of type `(String, A)`, where the heads of each pair are field names and the tails are the values of these fields. The same rules are in effect as for `Json.arr(...)`.

Here's an example of this DSL in action. Note that the syntax is terser than the constructor syntax introduced above:

<div class="row">
<div class="col-sm-6">
**DSL Syntax**

~~~ scala
Json.obj(
  "name" -> "Dave",
  "age" -> 35,
  "likes" -> Json.arr(
    "Scala",
    "Coffee",
    "Pianos"
  ),
  "dislikes" -> JsNull
}
~~~
</div>
<div class="col-sm-6">
**Constructor Syntax**

~~~ scala
JsObject(Seq(
  "name" -> JsString("Dave"),
  "age" -> JsNumber(35.0),
  "likes" -> JsArray(Seq(
    JsString("Scala"),
    JsString("Coffee"),
    JsString("Pianos")
  )),
  "dislikes" -> JsNull
))
~~~
</div>
</div>



## Converting Strings &hArr; JsValues

We can convert any JSON string to a `JsValue` using the `parse` method of [play.api.libs.json.Json]

~~~ scala
Json.parse("""{ "name": "Dave", "age": 35 }""")
// => JsObject(Seq(
//      "name" -> JsString("Dave"),
//      "age"  -> JsNumber(35.0)
//    ))

Json.parse("""[ 1, 2, 3 }""")
// throws com.fasterxml.jackson.core.JsonParseException
~~~

Note that we do not typically need to call this method directly -- `request.body.asJson` will parse a request's body as JSON (see [Parsing Requests](../basics/requests.html#bodies) in the previous chapter) and will swallow any exceptions raised by the `parse` method. This is preferable to us as functional programmers, as `Optional` return values are easier to reason about than exceptions.

The compliment of `Json.parse` is `Json.stringify`, which takes any `JsValue` and converts it to a minified JSON string. We can also use `Json.prettyPrint` to format the JSON string with newlines and indentation:

~~~ scala
Json.stringify(Json.obj("name" -> "Dave", "age" -> 35))
// => """{"name":"Dave","age":35}"""

Json.prettyPrint("""[ 1, 2, 3 }""")
// => """{
//      "name": "Dave",
//      "age": 35
//    }"""
~~~

## Deconstructing and Traversing JSON Data

Successfully parsing a string using `Json.parse` is not enough to fully process the information stored in the JSON data. `Json.parse` returns a value of type `JsValue`, but we don't know at compile time what type of `JsValue` we are going to get. Similarly, if our JSON contains a `JsObject` or `JsArray`, we don't know the types of any of its fields. So how can we process and interpret the JSON data?

### Pattern Matching

One way is to use *pattern matching*. This is quite convenient as the subtypes of `JsValue` are all case classes and case objects:

~~~ scala
val json = Json.parse(/* ... */)

json match {
  case JsObject(fields) => println("Object:\n  " + (fields mkString "  \n"))
  case JsArray(values)  => println("Array:\n  " + (values mkString "  \n"))
  case value            => println("Single value: " + value)
}
~~~

### Traversal (`\`, `\\` and `apply`)

Pattern matching only gets us so far -- one of the big flaws of matching by hand is that we can't easily *search* through the children of a `JsObject` or `JsArray` without writing loops. Fortunately, we can use three methods of `JsValue` to extract specific fields before we match:

 - `json \ "name"`  extracts a field from `json` assuming (a) `json` is a `JsObject` and (b) the field `"name"` exists;
 - `json(index)`    extracts a field from `json` assuming (a) `json` is a `JsArray` and (b) the `index` exists;
 - `json \\ "name"` extracts *all* fields named `"name"` from `json` and *any of its descendents*.

Here is an example of each type of traversal in operation:

~~~ scala
val json = Json.arr(
  Json.obj(
    "name" -> "Dave",
    "likes" -> Json.arr("Scala", "Coffee", "Pianos")),
  Json.obj(
    "name" -> "Noel",
    "likes" -> Json.arr("Scala", "Cycling", "Barbequeues")))

// We use the `apply` method to extract the first person
val person: JsValue = json(0) // == JsObject(...)

// We use `\` to extract the person's name:
val name: JsValue = person \ "name" // == JsString("Dave")

// Finally, we use `\\` to extract all likes from the data:
val likes: Seq[JsValue] = json \\ "likes" // == Seq(JsArray(...), JsArray(...))
~~~

This begs the question: what happens when we use `\` and `apply` and the specified field *doesn't* exist? We can see from the Scaladoc for [play.api.libs.json.JsValue] that each method returns a `JsValue` -- how do the methods represent failure?

We lied earlier when we said there were only five subtypes of `JsValue`. There is actually a sixth subtype, `JsUndefined`, that is used to represent the failure to find a field:

~~~ scala
case class JsUndefined(/* ... */) extends JsValue
~~~

The `\` and `apply` methods of `JsUndefined` each themselves return `JsUndefined`, so we can freely navigate around a JSON data structure using whole sequences of operations without having to check whether the data matches our expectations at every step. Here's an example:

~~~ scala
val x: JsValue = json \ "badname" // => JsUndefined(...)
val y: JsValue = json(2)          // => JsUndefined(...)
val z: JsValue = json(2) \ "name" // => JsUndefined(...)
~~~

Note that we have ignored the contents of `JsUndefined` as they typically aren't used in user code.

### Putting it All Together

Traversal and pattern matching provide a powerful combination of techniques for performing an ad hoc dissection of JSON data. The most common idiom is to extract specific fields using traversal operators, and perform pattern matching on the extracted data to see if it matches our needs. For example:

~~~ scala
json match {
  case JsArray(people) =>
    for((person, index) <- people.zipWithIndex) {
      (person \ "name") match {
        case JsString(name) =>
          println(s"Person $index name is $name")
      }
    }

  case _ =>
    // Not an array of people
}
~~~

While this approach is convenient for ad-hoc operations on semi-structured data, it is cumbersome as a means to implement detailed parsing and validation. In the next section we will see how to reliably read and write structured data and define robust mappings between Scala data types and JSON.

## Take Home Points

We model JSON in Play using `JsValues`, which act as an intermediary between raw string JSON data and well-typed Scala domain objects. There are subtypes of `JsValue` for each of the six main types of JSON data -- `JsObject`, `JsArray`, `JsString`, `JsNumber`, `JsBoolean`, and `JsNull`.

`JsValues` form a DOM-like tree that we can traverse using `\`, `\\` and `apply`, and destructure using pattern matching. These operations allow us to do ad-hoc processing of JSON data with relative ease, but they quickly become cumbersome when parsing complex data structures.

In the next sections we will introduce a more robust way of converting between JSON and well-typed Scala values using objects called `Reads` and `Writes` to model the transformations.
