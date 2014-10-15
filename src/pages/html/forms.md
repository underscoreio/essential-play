---
layout: page
title: Form handling
---

# Form handling

Play's forms library centers around objects of type [play.api.data.Form]. These objects represent a combination of mapping information and form data, allowing us to perform four important operations:

 1. *parse* incoming request data to create typed data values;
 2. *validate* the incoming data, allowing us to recover if the user made a mistake;
 3. *generate* HTML forms and inputs using stored data (and error messages from failed validations);
 4. *populate* generated HTML with values taken from data values.

We will cover each of these processes in the following sections. This section covers parsing, validation, and population of forms. HTML generation is covered in the next section.

[play.api.data.Form]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.data.Form

## *Forms* and *Mappings*

`Forms` define mappings between form data and typed data values. To define a form, we first need to define the *data type* we want to represent:

~~~ scala
case class Cat(name: String, born: Int, likesTuna: Boolean)
~~~

Incoming form data is represented by Play as a `Map[String, String]`. We create a `Form` by defining the mappings between the raw form data and our typed data value:

~~~ scala
import play.api.data._
import play.api.data.Forms._

val catMapping: Mapping[Cat] = mapping(
  "name"      -> text,
  "born"      -> number,
  "likesTuna" -> boolean
)(Cat.apply)(Cat.unapply)
~~~

Let's dissect this definition:

The methods `text`, `number`, and `boolean` come from [play.api.data.Forms]. They create field `Mappings` between `Strings` and the relevant Scala types:

[play.api.data.Forms]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.data.Forms$

~~~ scala
val nameMapping: Mapping[String]  = text
val bornMapping: Mapping[Int]     = number
val tunaMapping: Mapping[Boolean] = boolean
~~~

The `mapping` method, also from `Forms`, associates a name with each field and declares how to combine them together into an overall data value:

~~~ scala
val catMapping: Mapping[Cat] = mapping(
  "name"      -> text,
  "born"      -> number,
  "likesTuna" -> boolean
)(Cat.apply)(Cat.unapply)
~~~

The final `Mapping` can be used to create a `Form` of the relevant type:

~~~ scala
val catForm: Form[Cat] = Form(catMapping)
~~~

We typically only use the `Form` object in application code, so we often write all of this as a single definition:

~~~ scala
val catForm = Form(mapping(
  "name"      -> text,
  "born"      -> number,
  "likesTuna" -> boolean
)(Cat.apply)(Cat.unapply))
~~~

## Handling form data

A `Form` is actually a combination of the mappings we defined above and a set of data values. Our initial `catForm` is empty, but we can use it to create a *populated form* from an incoming request. This process is called *binding* the request:

~~~ scala
val populatedForm = catForm.bindFromRequest()(request)
~~~

The `bindFromRequest` method creates a new `Form`, fills it with the data from `request`, and attempts to parse and validate it to produce a `Cat`. The results of parsing are stored in `populatedForm` along-side the original request data. Note that `populatedForm` is an entirely new object -- `catForm` is left untouched.

Binding a request has two possible outcomes: either we manage to extract a valid `Cat` from the submitted data, or the bind fails and we're left with a set of error messages. We can use the `fold` method on `Form` to describe what to do in each case:

~~~ scala
val result: X = populatedForm.fold[X](
  // Failure function:
  (errorForm: Form[Cat]) => {
    // Handle the failure, return an X
  },
  // Success function:
  (cat: Cat) => {
    // Handle the success, return an X
  }
)
~~~

`fold` requires both of the argument functions to return the same type -- the result of the fold is the result of whichever function gets called. We typically implement each function to return a `Result` to send to the user in that case:

~~~ scala
def submitCatForm = Action { request =>
  catForm.bindFromRequest()(request).fold(
    (formContainingErrors: Form[Cat]) => {
      // Show the user a completed form with error messages:
      BadRequest(views.html.catFormTemplate(formContainingErrors))
    },
    // Failure function:
    (cat: Cat) => {
      // Save `cat` to a database and redirect:
      Redirect("/")
    }
  )
}
~~~

Our failure handler passes the `formContainingErrors` to a template that generates a filled form, complete with error messages. We will discuss how this works in the next section.

## Form validation

Binding a request attempts to parse the incoming data, but it can also *validate* once parsed. The `Forms` object contains constructors for various types of validated `Mapping`, and we can add arbitrary validation constraints via `Mapping's` `verifying` method:

~~~ scala
import play.api.data.validation.Constraints.min

val catForm: Form[Cat] = Form(mapping(
  "name"      -> nonEmptyText,
  "born"      -> number.verifying(min(0)),
  "likesTuna" -> ignored(true)
)(Cat.apply)(Cat.unapply))
~~~

The `fold` method invokes the error callback if the incoming data cannot be parsed or any of the validation rules fails.

Play provides lots of options for parsing and validating, including adding multiple and custom validation constraints to fields and mapping hierarchical and sequential data. See the [documentation for Forms], the Scaladoc for [play.api.data.Forms], and the Scaladoc for [play.api.data.validation.Constraints] for more information.

[documentation for Forms]: https://www.playframework.com/documentation/2.2.0/ScalaForms
[play.api.data.Forms]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.data.Forms$
[play.api.data.validation.Constraints]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.data.validation.Constraints$

## Take home points

In this section we saw how to creaate `Form` objects and use them to parse and validate incoming form data.

We create `Forms` using `Mappings` defined using methods from [play.api.data.Forms].

We extract data from requests using the `bindFromRequest` method of `Form`. Binding may succeed or fail, so we specify behaviours in either case using the `fold` method.

In the next section we will see how to use `Forms` to generate HTML `<form>` and `<input>` tags, pre-populate inputs with text taken from typed Scala data, and report error messages back to the user.

[play.api.data.Forms]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.data.Forms$