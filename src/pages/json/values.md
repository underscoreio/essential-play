## Modelling JSON

Play models JSON data using a family of case classes of type [`play.api.libs.json.JsValue`], representing each of the data types in the [JSON specification](link-json-spec):

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
*JSON Data*

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
*Equivalent `JsValue`*

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

The Scala code above is much longer than raw JSON---the `JsString` and `JsNumber` wrappers add to the verbosity.  Fortunately, Play provides two methods on [`play.api.libs.json.Json`] that omit a lot of the boilerplate:

 - `Json.arr(...)` creates a `JsArray`. The method takes any number of parameters, each of which must be a `JsValue` or a type that can be implicitly converted to one.

 - `Json.obj(...)` creates a `JsObject`. The method takes any number of parameters, each of which must be a pair of a `String` and a `JsValue` or convertible.

Here's an example of this in action. Note that the DSL code on the left is much terser than constructor code on the right:

<div class="row">
<div class="col-sm-6">
*DSL Syntax*

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
*Constructor Syntax*

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

As we saw in Chapter 2, Play contains built-in functionality for extracting `JsValues` from `Request[AnyContent]` and serializing them in `Results`:

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

// If we use the Action.apply(bodyParser)(handlerFunction) method here...
def index = Action(parse.json) { request =>
  // ...the request body is automaically JSON -- no need to call `asJson`:
  val json: JsValue = request.body

  Ok(Json.obj(
    "message" -> "The request contained JSON data",
    "data"    -> json
  ))
}
~~~

<div class="callout callout-warning">
*Parsing and Stringifying JSON*

As Play provides us with the means to extract `JsValues` from incoming `Requests`, we typically don't have to directly parse stringified JSON ourselves. If we do, we can use the `parse` method of [`play.api.libs.json.Json`]:

~~~ scala
Json.parse("""{ "name": "Dave", "age": 35 }""")
// res0: JsValue = JsObject(Seq(
//   ("name", JsString("Dave")),
//   ("age",  JsNumber(35.0))))

Json.parse("""[ 1, 2, 3 }""")
// throws com.fasterxml.jackson.core.JsonParseException
~~~

The compliment of `Json.parse` is `Json.stringify`, which converts a `JsValue` to a minified string. We can also use `Json.prettyPrint` to format the string with newlines and indentation:

~~~ scala
Json.stringify(Json.obj("name" -> "Dave", "age" -> 35))
// res1: String = """{"name":"Dave","age":35}"""

Json.prettyPrint(Json.obj("name" -> "Dave", "age" -> 35))
// res2: String = """{
//    "name": "Dave",
//    "age": 35
// }"""
~~~
</div>

### Deconstructing and Traversing JSON Data

Getting data out of a request is just the first step in reading it. A client can pass us any data it likes---valid or invalid---so we need to know how to traverse `JsValues` and extract the fields we need.

#### Pattern Matching

One way of deconstructing `JsValues` is to use *pattern matching*. This is convenient as the subtypes are all case classes and case objects:

~~~ scala
val json = Json.parse("""
{
  "name": "Dave",
  "likes": [ "Scala", "Coffee", "Pianos" ]
}
""")
// json: play.api.libs.json.JsValue = ↩
//   {"name":"Dave","likes":["Scala","Coffee","Pianos"]}

json match {
  case JsObject(fields) => "Object with fields: " + (fields mkString ", ")
  case JsArray(values)  => "Array with values: " + (values mkString ", ")
  case other            => "Single value: " + other
}
// res0: String = Object with fields: ↩
//   (name,"Dave"), ↩
//   (likes,["Scala","Coffee","Pianos"])
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
// json: play.api.libs.json.JsArray = [ ↩
//   {"name":"Dave","likes":["Scala","Coffee","Pianos"]}, ↩
//   {"name":"Noel","likes":["Scala","Cycling","Barbequeues"]}]

val person: JsValue = json(0)
// person: play.api.libs.json.JsValue = ↩
//   {"name":"Dave","likes":["Scala","Coffee","Pianos"]}

val name: JsValue = person \ "name"
// name: play.api.libs.json.JsValue = "Dave"

val likes: Seq[JsValue] = json \\ "likes"
// likes: Seq[play.api.libs.json.JsValue] = ArrayBuffer( ↩
//   ["Scala","Coffee","Pianos"], ↩
//   ["Scala","Cycling","Barbequeues"])
~~~

This begs the question: what happens when we use `\` and `apply` and the specified field *doesn't* exist? We can see from the Scaladoc for [`play.api.libs.json.JsValue`] that each method returns a `JsValue`---how do the methods represent failure?

We lied earlier about the subtypes of `JsValue`. There is a actually a sixth subtype, `JsUndefined`, that Play uses to represent the failure to find a field:

~~~ scala
case class JsUndefined(error: => String) extends JsValue
~~~

The `\`, `apply`, and `\\` methods of `JsUndefined` each themselves return `JsUndefined`. This means we can freely traverse JSON data using sequences of operations without worrying about failure:

~~~ scala
val x: JsValue = json \ "badname"
// x: play.api.libs.json.JsValue = JsUndefined( ↩
//   'badname' is undefined on object: [{"name":"Dave", ...

val y: JsValue = json(2)
// y: play.api.libs.json.JsValue = JsUndefined( ↩
//   Array index out of bounds in [{"name":"Dave", ...

val z: JsValue = json(2) \ "name"
// z: play.api.libs.json.JsValue = JsUndefined( ↩
//   'name' is undefined on object: JsUndefined( ↩
//     Array index out of bounds in [{"name":"Dave",...
~~~

In the example, the expression to calculate `z` actually fails twice: first at the call to `apply(2)` and second at the call to `\ "name"`. The implementation of `JsUndefined` carries the errors over into the final result, where the error message (if we choose to examine it) tells us exactly what went wrong.

#### Parsing Methods

We can use two methods, `as` and `asOpt`, to convert JSON data to regular Scala types.

The `as` method is most useful when exploring JSON in the REPL or unit tests:

~~~ scala
val name = (json(0) \ "name").as[String]
// name: String = Dave
~~~

If `as` cannot convert the data to the type requested, it throws a run-time exception. This makes it dangerous for use in production code:

~~~ scala
val name = (json(0) \ "name").as[Int]
// play.api.libs.json.JsResultException: ↩
//   JsResultException(List( ↩
//      (JsPath, List(ValidationError(error.expected.jsnumber)))))
//   at ...
//   at ...
//   at ...
~~~

The `asOpt` method provides a safer way to extract data---it attempts to parse the JSON as the desired type, and returns `None` if it fails. This is a better choice for use in application code:

~~~ scala
scala> val name = (json(0) \ "name").asOpt[Int]
// name: Option[Int] = None
~~~

<div class="callout callout-warning">
*Extracting data with `as` and `asOpt`*

We might reasonably ask the questions: what Scala data types to `as` and `asOpt` work with, and how do they know the JSON encodings of those types?

Each method accepts an `implicit` parameter of type `Reads[T]` that explains how to parse JSON as the target type `T`. Play provides default `Reads` implementations for basic types such as `String` and `Seq[Int]`, and we can define custom `Reads` for our own types. We will cover `Reads` in detail later in this Chapter.
</div>

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
