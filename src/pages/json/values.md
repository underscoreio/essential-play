## Modelling JSON

Play models JSON data using a family of case classes of type [play.api.libs.json.JsValue], representing each of the data types in the [JSON specification](link-json-spec).

~~~ scala
package play.api.libs.json

sealed trait JsValue
final case class JsObject(fields: Seq[(String, JsValue)]) extends JsValue
final case class JsArray(values: Seq[JsValue]) extends JsValue
final case class JsString(value: String) extends JsValue
final case class JsNumber(value: Double) extends JsValue
final case class JsBoolean(value: Boolean) extends JsValue
final case object JsNull extends JsValue
~~~

In this section we will discuss basic JSON manipulation and traversal, which is useful for ad hoc operations on JSON data. In the following sections we will see how to define mappings between `JsValues` and types from our domain, and use them to validate the JSON we receive in `Requests`.



### Representing JSON in Scala

We can represent any fragment of JSON data using `JsValue` and its subtypes:

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

The Scala code above is much longer than raw JSON -- the `JsString` and `JsNumber` wrappers add to the verbosity.  Fortunately, Play provides two methods on [play.api.libs.json.Json] that omit a lot of the boilerplate:

 - `Json.arr(...)` creates a `JsArray`. The method takes any number of parameters, each of which must be a `JsValue` or a type that can be implicitly converted to one.

 - `Json.obj(...)` creates a `JsObject`. The method takes any number of parameters, each of which must be a pair of a `String` and a `JsValue` or convertible.

Here's an example of this DSL in action. Note that the code on the left is much terser than constructor code on the right:

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



### JSON *Requests* and *Results*

Play contains built-in functionality for extracting `JsValues` from `Requests[AnyContent]` and serializing them in `Results`:

~~~ scala
def index = Action { request =>
  request.body.asJson match {
    case Some(json) =>
      Ok(Json.obj(
        "message" -> "The request contained JSON data",
        "data"    -> json
      ))

    case None =>
      Ok(Json.obj(
        "message" -> "The request contained no JSON data"
      ))
  }
}
~~~

If we're writing API endpoint that *must* accept JSON, we can use the built-in JSON body parser to receive a `Request[JsValue]` instead. Play will respond with a *400 Bad Request* result if the request does not contain JSON:

~~~ scala
import play.api.mvc.BodyParsers.parse

def index = Action(parse.json) { request =>
  val json: JsValue = request.body

  Ok(Json.obj(
    "message" -> "The request contained JSON data",
    "data"    -> json
  ))
}
~~~

<div class="callout callout-warning">
*Parsing and Stringifying JSON*

We typically don't have to directly parse stringified JSON If we do, we can use the `parse` method of [play.api.libs.json.Json]

~~~ scala
Json.parse("""{ "name": "Dave", "age": 35 }""")
// => JsObject(Seq(
//      "name" -> JsString("Dave"),
//      "age"  -> JsNumber(35.0)
//    ))

Json.parse("""[ 1, 2, 3 }""")
// throws com.fasterxml.jackson.core.JsonParseException
~~~

The compliment of `Json.parse` is `Json.stringify`, which converts a `JsValue` to a minified string. We can also use `Json.prettyPrint` to format the string with newlines and indentation:

~~~ scala
Json.stringify(Json.obj("name" -> "Dave", "age" -> 35))
// => """{"name":"Dave","age":35}"""

Json.prettyPrint(Json.obj("name" -> "Dave", "age" -> 35))
// => """{
//      "name": "Dave",
//      "age": 35
//    }"""
~~~
</div>

### Deconstructing and Traversing JSON Data

Getting data out of a request is just the first step in reading it. A client can pass us any data it likes -- valid or invalid -- so we need to know how to traverse `JsValues` and extract the fields we need:

#### Pattern Matching

One way of deconstructing `JsValues` is to use *pattern matching*. This is convenient as the subtypes are all case classes and case objects:

~~~ scala
val json = Json.parse(/* ... */)

json match {
  case JsObject(fields) => println("Object:\n  " + (fields mkString "  \n"))
  case JsArray(values)  => println("Array:\n  " + (values mkString "  \n"))
  case other            => println("Single value: " + other)
}
~~~

#### Traversal Methods

Pattern matching only gets us so far. We can't easily *search* through the children of a `JsObject` or `JsArray` without looping. Fortunately, `JsValue` contains three methods to drill down to specific fields before we match:

 - `json \ "name"`  extracts a field from `json` assuming (a) `json` is a `JsObject` and (b) the field `"name"` exists;
 - `json(index)`    extracts a field from `json` assuming (a) `json` is a `JsArray` and (b) the `index` exists;
 - `json \\ "name"` extracts *all* fields named `"name"` from `json` and *any of its descendents*.

Here is an example of each type of traversal in operation:

~~~ scala
val json = Json.arr(
  Json.obj(
    "name"  -> "Dave",
    "likes" -> Json.arr("Scala", "Coffee", "Pianos")
  ),
  Json.obj(
    "name"  -> "Noel",
    "likes" -> Json.arr("Scala", "Cycling", "Barbequeues")
  )
)

// We use the `apply` method to extract the first person
val person: JsValue = json(0) // == JsObject(...)

// We use `\` to extract the person's name:
val name: JsValue = person \ "name" // == JsString("Dave")

// Finally, we use `\\` to extract all likes from the data:
val likes: Seq[JsValue] = json \\ "likes" // == Seq(JsArray(...), JsArray(...))
~~~

This begs the question: what happens when we use `\` and `apply` and the specified field *doesn't* exist? We can see from the Scaladoc for [play.api.libs.json.JsValue] that each method returns a `JsValue` -- how do the methods represent failure?

We lied earlier about the subtypes of `JsValue`. There is a actually a sixth subtype, `JsUndefined`, that Play uses to represent the failure to find a field:

~~~ scala
case class JsUndefined(/* ... */) extends JsValue
~~~

The `\` and `apply` methods of `JsUndefined` each themselves return `JsUndefined`. This means we can freely traverse JSON data using sequences of operations without worrying about failure:

~~~ scala
val x: JsValue = json \ "badname" // => JsUndefined(...)
val y: JsValue = json(2)          // => JsUndefined(...)
val z: JsValue = json(2) \ "name" // => JsUndefined(...)
~~~

Note that we have ignored the contents of `JsUndefined` as they typically aren't used in user code.

A useful trick for exploring JSON in the REPL, or in unit tests, we can use the `as` method to extract values:

~~~ scala
val name = (json(0) \ "name").as[String]
// => name: String = Dave
~~~

We say only for use in the REPL or tests because if `as` cannot convert to the type requested, a run-time exception is thrown:

~~~ scala
val name = (json(0) \ "name").as[Int]
// => play.api.libs.json.JsResultException: JsResultException(errors:List((,List(ValidationError(error.expected.jsnumber,WrappedArray())))))
~~~

If you think using `as` would be handy, hang on, because there is a better way which we will come to. But if you still really want to use `as` prefer the `asOpt` variant. This evaluates to a `None` if it cannot convert the JSON value:

~~~ scala
scala> val name = (json(0) \ "name").asOpt[Int]
// => name: Option[Int] = None
~~~

#### Putting It All Together

Traversal and pattern matching are complimentary techniques for dissecting JSON data. We can extract specific fields using traversal, and pattern match on them to extract Scala values:

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

This approach is convenient for ad-hoc operations on semi-structured data. However, it is cumbersome for complex parsing and validation. In the next sections we will introduce *formats* that map JSON data onto Scala types, allowing us to read and write complex values in a single step.

### Take Home Points

We represent JSON data in Play using objects of type `JsValue`.

We can easily extract `JsValues` from `Requests[AnyContent]`, and serialize them in `Results`.

We can extract meaningful Scala values from `JsValues` using a combination of *pattern matching* and *traversal methods* (`\`, `\\` and `apply`).

Pattern matching and traversal only tend to be convenient in simple situations. They quickly become cumbersome when operating on complex data. In the next sections we will introduce `Writes`, `Reads`, and `Format` objects to map complex Scala data types to JSON.
