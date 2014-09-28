---
layout: page
title: JSON Formats
---

# JSON Formats

In the previous sections we saw how to use the `Reads` and `Writes` type classes to convert between JSON and well-typed Scala data. In this section we introduce a third type, `Format`, that subsumes both `Reads` and `Writes`.

## Meet *Format*

We commonly want to describe reading and writing together at the same time. The `Format` trait is a convenience that allows us to do just that:

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
Json.fromJson(Json.obj(
  "name"    -> "Eric Wimp",
  "address" -> Json.obj
    "name"   -> 29,
    "street" -> "Acacia Road"
  )
))
~~~

`Format` is really just a convenience. We can do everything we need to using `Reads` and `Writes` alone, but sometimes it is similar to group both sets of functionality in the same object.

## Take Home Points

TODO
