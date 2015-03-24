## JSON Formats

In the previous sections we saw how to use the `Reads` and `Writes` traits to convert between JSON and well-typed Scala data. In this section we introduce a third trait, `Format`, that subsumes both `Reads` and `Writes`.

### Meet *Format*

We often want to describe reading and writing together at the same time. The `Format` trait is a convenience that allows us to do just that:

~~~ scala
package play.api.libs.json

trait Format[A] extends Reads[A] with Writes[A]
~~~

Because `Format` is a subtype of `Reads` and `Writes`, it can be used by both `Json.toJson` and `Json.fromJson` as described in the previous sections. Play also defines a convient macro, `Json.format`, to define a format for a case class in one line. Here's a synopsis:

~~~ scala
case class Address(number: Int, street: String)
case class Person(name: String, address: Address)

implicit val addressFormat = Json.format[Address]
implicit val personFormat  = Json.format[Person]

// This compiles because we have a `Writes[Address]` in scope:
Json.toJson(Address(29, "Acacia Road"))

// This compiles because we have a `Reads[Person]` in scope:
Json.fromJson[Person](Json.obj(
  "name"    -> "Eric Wimp",
  "address" -> Json.obj(
    "number" -> 29,
    "street" -> "Acacia Road"
  )
))
~~~

`Format` is really just a convenience. We can do everything we need to using `Reads` and `Writes`, but sometimes it is simpler to group both sets of functionality in a single object.

### Take Home Points

`Format[A]` is a subtype of `Reads[A]` and `Writes[A]` that provides both sets of functionality and can be used with `Json.toJson` and `Json.fromJson`.

Play provides the `Json.format` macro that defines `Formats` for case classes.

It is often convenient to use `Formats` to define reading and writing functionality in one go. However, it is sometimes necessary or convenient to define `Reads` and `Writes` separately.

### Exercise: Message in a Bottle

The `chapter4-json-macro` directory in the exercises contains an example `Message` datatype
and unit tests testing its serialization to/from JSON.

Use Play's `Json.format` macro to define a `Format[Message]` that passes the unit tests.
Don't alter the tests in any way!

<div class="callout callout-info">
*Plain SBT Project*

The code in this exercise is a plain Scala project rather than a Play application.
You will notice the following differences from the Play web applications you've been working with:

 - the SBT prompt is a simple `>` rather than the usual colour-coded project name;
 - application source is in the `src/main/scala` directory instead of `app`;
 - unit test source is in the `src/test/scala` directory instead of `test`.

You can still run the unit tests with the `test` and `~test` commands in SBT.
</div>

<div class="solution">
Play's macro defines everything for us in a single line.
Be sure to mark your format as `implicit` so the unit tests can pick it up:

~~~ scala
implicit val messageFormat = Json.format[Message]
~~~
</div>