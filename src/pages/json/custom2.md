## Custom Formats: Part 2

Writing complex `Reads` using simple Scala code is difficult. Every time we unpack a field from the JSON, we have to consider potential errors such as the field being missing or of the wrong type. What is more, we have to remember the nature and location of every error we encounter for inclusion in the `JsError`.

Fortunately, Play provides a *format DSL* for creating `Reads`, `Writes`, and `Formats`, based on a general functional programming pattern called *applicative builders*. In this section we will dissect the DSL and see how it all works.

### Using Play's Format DSL

Let's start with an example of a `Reads`. Later on we'll see how the same pattern applies for `Writes` and `Formats`. We can write a `Reads` for our `Address` class as follows:

~~~ scala
import play.api.libs.json._
import play.api.libs.functional.syntax._

implicit val addressReads: Reads[Address] = (
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]
)(Address.apply)
~~~

In a nutshell, this code parses a JSON object by extracting its `"number"` field as an `Int`, its `"street"` field as a `String`, combining them via the `and` method, and feeding them into `Address.apply`.

We have a lot more flexibility using this syntax than we do with `Json.reads`. We can change the field names for `"number"` and `"street"`, introduce default values for fields, validate that the house number is greater than zero, and so on.

We won't cover all of these options here---the full DSL is described in the [Play documentation][docs-json-combinators]. In the remainder of this section we will dissect the `addressReads` example above and explain how it works.

<div class="callout callout-warning">
*Applicative Builders*

The technical name for this pattern of defining `Reads`, `Writes`, or `Formats` for each field and passing them to a constructor function is the *"applicative builder pattern"*. *Applicatives* are a powerful general functional programming concept explored in libraries such as Scalaz and the `play.api.libs.functional` package.

A full discussion of applicatives and applicative builders is beyond the scope of this book, although we do cover them (and many similarly useful functional programming concepts) in detail in [Advanced Scala with Scalaz][link-advanced-scala-scalaz].
</div>

#### Dissecting the DSL

Let's build the `addressReads` example from the ground up, examining each step in the process:

**Step 1. Describe the locations of fields**

~~~ scala
(JsPath \ "number")
(JsPath \ "street")
~~~

These are the same `JsPath` objects we saw in the section on `Reads`. They represent paths into a data structure (in this case the `"number"` and `"street"` fields respectively).

**Step 2. Read fields as typed values**

We create `Reads` for each field using the `read` method of `JsPath`:

~~~ scala
(JsPath \ "number").read[Int]
(JsPath \ "street").read[String]
~~~

The resulting `Reads` attempt to parse the corresponding fields as the specified types. Any failures are reported against the correct path in the resulting `JsError`. For example:

~~~ scala
val numberReads = (JsPath \ "number").read[Int]

numberReads.reads(Json.obj("number" -> 29))
// res0: JsResult[Int] = JsSuccess(29)

numberReads.reads(JsNumber(29))
// res1: JsResult[Int] = JsError(Seq(
//   (JsPath \ "number", Seq(ValidationError("error.path.missing")))))

numberReads.reads(Json.obj("number" -> "29"))
// res2: JsResult[Int] = JsError(Seq(
//   (JsPath \ "number", Seq(ValidationError("error.expected.jsnumber")))))
~~~

`JsPath` also contains a `write` method for building `Writes`, and a `format` method for building `Formats`:

~~~ scala
val numberWrites: Writes[Int]    = (JsPath \ "number").write[Int]
val streetFormat: Format[String] = (JsPath \ "street").format[String]
~~~

**Step 3. Aggregate the fields into a tuple**

We combine our two `Reads` using an `and` method that is brought into scope implicitly from the `play.api.libs.functional.syntax` package:

~~~ scala
import play.api.libs.functional.syntax._

val readsBuilder =
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]
~~~

The result of the combination is a *builder* object that we can use to create larger `Reads` objects. The builder contains methods that allow us to specify how to aggregate the fields, and return a new `Reads` for the aggregated result type.

More formally, if we combine a `Reads[A]` and a `Reads[B]` using `and`, we get a *`Reads` builder* of type `CanBuild2[Int, String]`. Builders have the following methods:

: Reads builder methods

------------------------------------------------------------------------
Type of `Reads` builder  Method    Parameters      Returns
------------------------ --------- --------------- ---------------------
`CanBuild2[A,B]`         `tupled`  None            `Reads[(A,B)]`

`CanBuild2[A,B]`         `apply`   `(A,B) => X`    `Reads[X]`

`CanBuild2[A,B]`         `and`     `Reads[C]`      `CanBuild3[A,B,C]`

`CanBuild3[A,B,C]`       `tupled`  None            `Reads[(A,B,C)]`

`CanBuild3[A,B,C]`       `apply`   `(A,B,C) => X`  `Reads[X]`

`CanBuild3[A,B,C]`       `and`     `Reads[C]`      `CanBuild4[A,B,C,D]`

`CanBuild4[A,B,C,D]`     etc...    etc...          etc...
------------------------------------------------------------------------

The idea of the builder pattern is to use the `and` method to create progressively larger builders (up to `CanBuild21`), and then call `tupled` or `apply` to create a `Reads` for our result type. Let's look at `tupled` as an example:

~~~ scala
val tupleReads: Reads[(Int, String)] = readsBuilder.tupled
// tupleReads: Reads[(Int, String)] = ...

tupleReads.reads(Json.obj("number" -> 29, "street" -> "Acacia Road"))
// res0: JsResult[(Int, String)] = ↩
//   JsSuccess((29, "Acacia Road"))

tupleReads.reads(Json.obj("number" -> "29", "street" -> null))
// res1: JsResult[(Int, String)] = ↩
//   JsError(Seq(
//     (JsPath \ "number", Seq(ValidationError("error.expected.jsnumber"))),
//     (JsPath \ "street", Seq(ValidationError("error.expected.jsstring")))))
~~~

`tupleReads` is built from the `Reads` for `"number"` and `"street"`. It extracts thw two fields from the JSON and combines them into a tuple of type `(Int, String)`. If fields are missing or malformed, `tupleReads` accumulates the error messages in the `JsResult`. In step 4 below we'll see how to use the `apply` method instead of `tupled` to combine the fields into an `Address`.

There are equivalent sets of builders for `Writes` and `Formats` types. All we have to do is combine two `Writes` or `Formats` using `and` to create the relevant `CanBuild2` and do from there.

**Step 4. Aggregate the fields into an *Address* **

Instead of using `tupled`, we can call our builder's `apply` method to create a `Reads` that aggregates values in a different way. As we can see in the table above, the `apply` method of `CanBuild2` accepts a constructor-like function of type `(A, B) => C` and returns a `Reads[C]`:

~~~ scala
val constructor = (a: Int, b: String) => Address(a, b)

val addressReads = readsBuilder.apply(constructor)
// addressReads: Reads[Address] = ...
~~~

If we substitute in some definitions and use some nicer syntax, we can see that this definition of `addressReads` is equivalent to our original example:

~~~ scala
val addressReads = (
  (JsPath \ "number").read[Int] and
  (JsPath \ "street").read[String]
)(Address.apply)
// addressReads: Reads[Address] = ...
~~~

As we can see from the types in the table, we can combine more than two `Reads` using this approach. There are `CanBuild` types up to `CanBuild21`, each of which has an `apply` method that accepts a constructor with a corresponding number of parameters.

When building `Writes`, we supply extractor functions instead of constructors. Extractor functions accept a single parameter and return a tuple of the correct number of values. The semantics are identical to the `unapply` method on a case class's companion object:

~~~ scala
(
  (JsPath \ "number").write[Int] and
  (JsPath \ "street").write[String]
)(unlift(Address.unapply))
~~~

Note the use of `unlift` here, which converts the `unapply` method of type `Address => Option[(Int, String)]` to a function (technically a partial function) of type `Address => (Int, String)`. `unlift` is a utility method imported from `play.api.libs.functional.syntax` that has identical semantics to [`Function.unlift`][`scala.Function$`] from the Scala standard library.

When building `Formats` we have to supply both a constructor and an extractor function: one to combine the values in a read operation, and one to split them up in a write:

~~~ scala
(
  (JsPath \ "number").format[Int] and
  (JsPath \ "street").format[String]
)(Address.apply, unlift(Address.unapply))
~~~

#### Applying the DSL to a Java Class

We will finish with one last DSL example---a `Format` that extracts the temporal components (hour, minute, day, month, etc) from an instance of [`org.joda.time.DateTime`] class. Here we define our own constructor and extractor and use them in the `apply` method of our builder:

~~~ scala
import org.joda.time._

def createDateTime(yr: Int, mon: Int, day: Int, hr: Int, min: Int, ↩
      sec: Int, ms: Int) =
  new DateTime(yr, mon, day, hr, min, sec, ms)

def extractDateTimeFields(dt: DateTime): ↩
      (Int, Int, Int, Int, Int, Int, Int) =
  (dt.getYear, dt.getMonthOfYear, dt.getDayOfMonth,
   dt.getHourOfDay, dt.getMinuteOfHour, dt.getSecondOfMinute,
   dt.getMillisOfSecond)

implicit val dateTimeFormat: Format[DateTime] = (
  (JsPath \ "year").format[Int] and
  (JsPath \ "month").format[Int] and
  (JsPath \ "day").format[Int] and
  (JsPath \ "hour").format[Int] and
  (JsPath \ "minute").format[Int] and
  (JsPath \ "second").format[Int] and
  (JsPath \ "milli").format[Int]
)(createDateTime, extractDateTimeFields)
~~~

Note that we don't need to use `unlift` with `extractDateTimeFields` here because our method already returns a non-`Optional` tuple of the correct size.

### Take Home Points

In this section we introduced Play's *format DSL*, which we can use to create `Reads`, `Writes` and `Formats` for arbitrary types.

The format DSL uses an *applicative builder* pattern to combine `Reads`, `Writes` or `Formats` for individual fields.

The general pattern for using the DSL is as follows:

 1. decide what fields we want in our Scala data type;
 2. decide where each field is going to be located in the JSON;
 3. write `JsPaths` for each field, and convert them to `Reads`, `Writes` or `Formats` of the relevant types;
 4. combine the fields using `and` to create a builder;
 5. call the builder's `apply` method, passing in constructors and destructors (or hand-written equivalents) as appropriate.

In the next section we'll look at one last common use case: defining `Reads`, `Writes` and `Formats` for hierarchies of types.

### Exercise: A Dash of Colour

The `chapter4-color` directory in the exercises
contains a constructor and extractor method for
the most infamous of classes, `java.awt.Color`.

Write a JSON format for `Color` using the format DSL
and the methods provided.

Ensure your format passes the unit tests provided.
Don't alter the tests in any way!

<div class="solution">
The code is similar to the Joda Time example above.
In our model solution we've used the `~` method,
which is simply an alias for `and`, to create the builder.
There's no difference between `~` and `and` other
than aesthetic preference and the standard precedence rules
applied by Scala:

~~~ scala
implicit val ColorFormat = (
  (JsPath \ "red").format[Int] ~
  (JsPath \ "green").format[Int] ~
  (JsPath \ "blue").format[Int] ~
  (JsPath \ "alpha").format[Int]
)(createColor, expandColor)
~~~
</div>
