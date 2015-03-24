## Custom Formats: Part 1

So far in this chapter we have seen how to use the `Json.reads`, `Json.writes` and `Json.format` macros to define `Reads`, `Writes` and `Formats` for case classes. In this section, we will see what we can do when we are dealing with types that *aren't* case classes.

### Writing Formats by Hand

Play's JSON macros don't do anything for hierarchies of types---we have to implement these formats ourselves. Enumerations are a classic example covered below. There is a separate section at the end of this chapter that extends this pattern to generalized hierarchies of types.

Consider the following enumeration:

~~~ scala
sealed trait Color
case object Red   extends Color
case object Green extends Color
case object Blue  extends Color
~~~

Using pattern matching, we can easily create a simple format to render these colours as string constants---`"red"`, `"green"` and `"blue"`:

~~~ scala
import play.api.libs.json._
import play.api.data.validation.ValidationError

implicit object colorFormat extends Format[Color] {
  def writes(color: Color): JsValue = color match {
    case Red   => JsString("red")
    case Green => JsString("green")
    case Blue  => JsString("blue")
  }

  def reads(json: JsValue): JsResult[Color] = json match {
    case JsString("red")   => JsSuccess(Red)
    case JsString("green") => JsSuccess(Green)
    case JsString("blue")  => JsSuccess(Blue)
    case other =>
      JsError(ValidationError("error.invalid.color", other))
  }
}
~~~

We can easily adapt this code to create a separate `Reads` or `Writes`---we simply extend `Reads` or `Writes` instead of `Format` and remove the definition of `writes` or `reads` as appropriate.

<div class="callout callout-warning">
*Internationalization*

Note the construction of the `JsError`, which mimics the way Play handles internationalization of error messages. Each type of error has its own *error code*, allowing us to build internationalization tables on the client. The [built-in error codes][link-error-codes] are rather poorly documented---a list can be found in the Play source code.


</div>

Hand-writing `Formats` using pattern matching tends to be most convenient when processing atomic values that don't have any internal structure. However, hand-written `Formats` can become verbose and unwieldy as the complexity of the data increases.

### Take Home Points

We can write instances of `Reads`, `Writes`, and `Format` by hand using pattern matching, JSON manipulation, and traversal.

This approach is convenient for simple atomic types, but becomes unwieldy when processing types that have internal structure.

Fortunately, Play provides a simple DSL for writing more advanced `Reads`, `Writes` and `Formats`. This will be the focus of the next section.

### Exercise: Red Light, Green Light

The `chapter4-json-lights` directory in the exercises
contains a `TrafficLight` type encoded as a `sealed trait`.

Write a JSON format for `TrafficLight` by extending `Format` manually.
Use the following serialization:

 - `Red`   should be serialized as the number 0;
 - `Amber` should be serialized as the number 1;
 - `Green` should be serialized as the number 2.

Ensure your format passes the unit tests provided.
Don't alter the tests in any way!

<div class="solution">
The solution is very close to the code in the `colorFormat` example above.
The trick is that `JsNumbers` can be floating point---we
have to coerce the number in the data to an `Int` to match on it.
The solution below defines a custom extractor called `JsNumberAsInt` for this purpose
but any code that passes the tests will suffice:

~~~ scala
implicit object TrafficLightFormat extends Format[TrafficLight] {
  def reads(in: JsValue) = in match {
    case JsNumberAsInt(0) => JsSuccess(Red)
    case JsNumberAsInt(1) => JsSuccess(Amber)
    case JsNumberAsInt(2) => JsSuccess(Green)
    case _ => JsError("error.expected.trafficlight")
  }

  def writes(in: TrafficLight) = in match {
    case Red   => JsNumber(0)
    case Amber => JsNumber(1)
    case Green => JsNumber(2)
  }
}

object JsNumberAsInt {
  def unapply(value: JsValue): Option[Int] = {
    value match {
      case JsNumber(num) => Some(num.toInt)
      case _             => None
    }
  }
}
~~~
</div>
