---
layout: page
title: Formats for custom types
---

# Formats for custom types

So far in this chapter we have seen how to use the `Json.reads`, `Json.writes` and `Json.format` macros to define `Reads`, `Writes` and `Formats` for case classes. In this section, we will see what we can do when we are dealing with types that *aren't* case classes.

The examples in this section will deal with `Formats` as this is the most complicated of the three types. However, all of these approaches also work when implementing `Reads` and `Writes` individually.

## Writing simple formats by hand

Play's JSON macros don't do anything for hierarchies of types -- we have to implement these formats ourselves. Enumerations are a classic example covered below. There is a separate section at the end of this chapter on extending this pattern to generalized hierarchies of types.

Consider the following enumeration:

~~~ scala
sealed trait Color
case object Red   extends Color
case object Green extends Color
case object Blue  extends Color
~~~

A simple format for these colors would simply write them as a string constant -- `"red"`, `"green"` or `"blue"`. There are three subtypes of `Color` and three possible serializations -- the code below falls straight out of the type definitions using structural recursion:

~~~ scala
import play.api.libs.json._
import play.api.data.validation.ValidationError

implicit object lightFormat extends Format[Color] {
  def writes(color: Color): JsValue = color match {
    case Red   => JsString("red")
    case Green => JsString("green")
    case Blue  => JsString("blue")
  }

  def reads(json: JsValue): JsResult[Color] = json match {
    case JsString("red")   => JsSuccess(Red)
    case JsString("green") => JsSuccess(Green)
    case JsString("blue")  => JsSuccess(Blue)
    case other             => JsError(ValidationError("error.invalid.color", other))
  }
}
~~~

<div class="callout callout-warning">
#### Advanced: Internationalization

Note the construction of the `JsError`, which mimics the way Play handles internationalization of error messages. Each type of error has its own *error code*, allowing us to build internationalization tables on the client. The [built-in error codes] are rather poorly documented -- a list can be found in the Play source code.

[built-in error codes]: https://github.com/playframework/playframework/blob/2.3.x/framework/src/play/src/main/resources/messages.default#L21-L51
</div>

## Writing complex formats using the *Format* DSL

In complex cases it can become cumbersome to write `Formats` by hand using regular Scala code. Fortunately, Play provides a comprehensive *format DSL* that simplifies the creation of `Reads`, `Writes`, and `Formats`. The full DSL is described in the [Play documentation] -- what follows is a brief synopsis for completeness.

We will illustrate the format DSL by writing a `Reads` for our `Address` class by hand:

~~~ scala
import play.api.libs.json._
import play.api.libs.functional.syntax._

implicit val addressReads: Reads[Address] = (
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]
)(Address.apply)
~~~

There are similar DSLs for building `Writes` and `Formats`. There are also more advanced options available, such as embedding validation rules within the DSL. See the [Play documentation] for full details.

[Play documentation]: https://www.playframework.com/documentation/2.3.x/ScalaJsonCombinators

### Dissecting the DSL

Let's walk through the `Address` example step by step:

#### Step 1. Describe the locations of fields

~~~ scala
(JsPath \ "number")
(JsPath \ "street")
~~~

These are `JsPath` objects. They represent paths into a data structure (in this case the `"number"` and `"street"` fields respectively).

`JsPaths` contain methods for building `Reads`, `Writes` and `Formats`  that extract and manipulate the corresponding field. They are also used to represent the locations of read errors in instances of `JsError`.

#### Step 2: Read fields as typed values

~~~ scala
(JsPath \ "number").read[Int]
(JsPath \ "street").read[String]
~~~

`JsPath` has a `read` method that returns a `Reads` that attempts to parse the corresponding field as the specified type. Any failures are reported against that path. For example:

~~~ scala
val numberReads = (JsPath \ "number").read[Int]

numberReads.reads(Json.obj("number" -> 29))
// => JsSuccess(29)

numberReads.reads(Json.obj("number" -> "29"))
// => JsError(Seq(
//      (JsPath \ "number", Seq(ValidationError("error.expected.jsnumber")))
//    ))
~~~

#### Step 3: Combine the fields into a tuple

~~~ scala
(JsPath \ "number").read[Int] and
(JsPath \ "street").read[String]
~~~

The `and` method combines the two `Reads` together into a single `Reads` that extracts each field separately and combines them into a `Tuple2`:

~~~ scala
val tupleReads =
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]

tupleReads.reads(Json.obj("number" -> 29, "street" -> "Acacia Road"))
// => JsSuccess((29, "Acacia Road"))

tupleReads.reads(Json.obj("number" -> "29", "street" -> null))
// => JsError(Seq(
//      (JsPath \ "number", Seq(ValidationError("error.expected.jsnumber"))),
//      (JsPath \ "street", Seq(ValidationError("error.expected.jsstring")))
//    ))
~~~

Successive calls to `and` build `Reads` for a successively larger tuples. For example:

~~~ scala
intReads and stringReads and booleanReads // => Reads[(Int, String, Boolean)]
~~~

#### Step 4: Convert the tuple to a well-typed object

~~~ scala
(
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]
)(Address.apply)
~~~

The `apply` method on `Reads[(Int, String)]` accepts a function `(Int, String) => A` as a parameter and returns a `Reads[A]`. In this case we specify the `apply` method on `Address` as a parameter, resulting in a `Reads[Address]`.

If we were building a `Writes`, we would pass an `unapply` method as a parameter instead of an `apply` method. If we were defining a `Format`, we would pass in *both* methods.

<div class="callout callout-info">
#### Recipe for using the format DSL

In summary, the process described as above is as follows:

 1. decide what fields we want in our Scala data type;
 2. decide where each field is going to be located in the JSON;
 3. write `JsPaths` for each field, and convert them to `Reads`, `Writes` or `Formats` of the relevant types;
 4. tuple everything together with `and`;
 5. pass everything into an `apply` or `unapply` method as appropriate (if these methods don't exist, write your own)!
</div>

### Applying the DSL to a Java class

We will finish with one last example of using the DSL -- defining a `Format` that extracts the temporal components (hour, minute, day, month, etc) from an instance of [org.joda.time.DateTime] class:

~~~ scala
// First we need an equivalent of `apply` and `unapply` for our Java class:
def createDateTime(yr: Int, mon: Int, day: Int, hr: Int, min: Int, sec: Int, ms: Int) =
  new DateTime(yr, mon, day, hr, min, sec, ms)

def extractDateTimeFields(dt: DateTime): (Int, Int, Int, Int, Int, Int, Int) =
  (dt.getYear, dt.getMonthOfYear, dt.getDayOfMonth,
   dt.getHourOfDay, dt.getMinuteOfHour, dt.getSecondOfMinute,
   dt.getMillisOfSecond)

// Now writing our format becomes trivial:
implicit val dateTimeFormat: Format[DateTime] = (
  (JsPath \ "year").read[Int] and
  (JsPath \ "month").read[Int] and
  (JsPath \ "day").read[Int] and
  (JsPath \ "hour").read[Int] and
  (JsPath \ "minute").read[Int] and
  (JsPath \ "second").read[Int] and
  (JsPath \ "milli").read[Int]
)(createDateTime, extractDateTimeFields)
~~~

## Take home points

Play provides three traits that govern mappings between JSON and Scala data:

 - instances of `Reads[A]` accept parameters of type `JsValue` and attempt to convert them to Scala type `A`;
 - instances of `Writes[A]` accept parameters of type `A` and attempt to convert them to `JsValues`;
 - instances of `Format[A]` can perform both `Reads` and `Writes` functionality.

Play gives us three macros -- `Json.reads`, `Json.writes`, and `Json.format` -- that automatically generate `Reads`, `Writes`, and `Format` instances for case classes. However these do not work in all situations.

There are two ways of generating `Reads`, `Writes`, and `Formats` by hand:

 1. write the instances ourselves by extending the appropriate type and using JSON manipulation and traversal;
 2. use the reads/writes/format DSL provided by Play.

The two approaches are convenient in different situations. Experience indicates the approach 1 tends to be simpler when handling types with no internal structure, while approach 2 tends to be simpler when mapping compound data structures.

