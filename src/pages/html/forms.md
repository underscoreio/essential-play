---
layout: page
title: Form Handling
---

# Form Handling

In the previous section we saw how to send HTML data to web site users using Twirl templates. In this section we will look at receiving HTML form data from users.

Play's form handling library is based on objects of type [play.api.data.Form]. `Forms` are metadata objects that represent a combination of mapping information and form data. They allow us to perform four important operations:

 1. *parse* incoming request data to create typed values;
 2. *validate* the incoming data, allowing us to recover if the user made a mistake;
 3. *generate* HTML forms and inputs using stored data (and error messages from failed validations);
 4. *populate* generated HTML with values taken from data values.

The next two sections cover these topics. This section covers parsing and validation; the next section covers generation and pre-population of HTML `<form>` elements.



## *Forms* and *Mappings*

`Forms` define mappings between form data and typed *domain values* from our domain model. Here's an example:

~~~ scala
case class Todo(name: String, priority: Int, complete: Boolean)
~~~

Play represents incoming form data as a `Map[String, String]`. The `Form` object helps us convert the incoming form data to a `Todo` value. We create a `Form` by defining this mapping:

~~~ scala
import play.api.data._
import play.api.data.Forms._

val todoMapping: Mapping[Todo] = mapping(
  "name"      -> text,
  "priority"  -> number,
  "complete"  -> boolean
)(Todo.apply)(Todo.unapply)
~~~

The methods `text`, `number`, and `boolean` come from [play.api.data.Forms]. They create field `Mappings` between `Strings` and the relevant type for each field of `Todo`:


~~~ scala
val nameMapping:     Mapping[String]  = text
val priorityMapping: Mapping[Int]     = number
val tunaMapping:     Mapping[Boolean] = boolean
~~~

The `mapping` method, also from `Forms`, associates a name with each field and declares how to combine them together into an overall data value:

~~~ scala
val todoMapping: Mapping[Todo] = mapping(
  "name"     -> text,
  "priority" -> number,
  "complete" -> boolean
)(Todo.apply)(Todo.unapply)
~~~

The final `Mapping` can be used to create a `Form` of the relevant type:

~~~ scala
val todoForm: Form[Todo] = Form(todoMapping)
~~~

We typically use the `Form` object and not the `Mappings` in application code, so we can write all of this as a single definition:

~~~ scala
val todoForm = Form(mapping(
  "name"      -> text,
  "priority"  -> number,
  "complete"  -> boolean
)(Todo.apply)(Todo.unapply))
~~~

## Handling Form Data

A `Form` is a combination of the mappings we defined above and a set of data values. Our initial `todoForm` is empty, but we can combine it with incoming request data to create a *populated form*. This process is called *binding* the request:

~~~ scala
val populatedForm = todoForm.bindFromRequest()(request)
~~~

The `bindFromRequest` method creates a new `Form` and populates it with data from `request`. Besides caching the data in its raw form, `Form` and attempts to parse and validate it to produce a `Todo` item. The result is stored along-side the original request data in the new `populatedForm`. Binding is a a non-destructive operation -- `todoForm` is left untouched by the process.

There are two possible outcomes of binding a request:

 - the request data is successfully parsed and validated, creating a new `Todo` object;
 - the request data cannot be interpreted, resulting in a set of error messages to show the user.

`Form` stores the end result of the binding operation regardless of whether it succeeds or fails. We can extract the result using the `fold` method on `Form`, which accepts two function parameters to handle each case. `fold` returns the result of calling the relevant function:

~~~ scala
package play.api.data

trait Form[A] {
  def fold[B](hasErrors: Form[A] => B, success: A => B): B =
    // ...
}
~~~

It is common to call `fold` supplying failure and success functions that return `Results`. On failure we send the `<form>` back to the user with a set of error messages; on success we redirect the user to an appropriate page:

~~~ scala
def submitTodoForm = Action { request =>
  todoForm.bindFromRequest()(request).fold(
    (formContainingErrors: Form[Todo]) => {
      // Show the user a completed form with error messages:
      BadRequest(views.html.todoFormTemplate(formContainingErrors))
    },
    // Failure function:
    (todo: Todo) => {
      // Save `todo` to a database and redirect:
      Redirect("/")
    }
  )
}
~~~

## Form Validation

Binding a request attempts to parse the incoming data, but it can also *validate* once parsed. The form API contains methods for creating validation constraints and adding them to mappings. `Form.fold` invokes our failure callback if any of our constraints are not satisfied:

~~~ scala
import play.api.data.validation.Constraints.min

val todoForm: Form[Todo] = Form(mapping(
  "name"      -> nonEmptyText,                        // cannot be ""
  "priority"  -> number.verifying(min(1) and max(3)), // must be 1 to 3
  "complete"  -> boolean                              // no validation
)(Todo.apply)(Todo.unapply))
~~~

Play provides lots of options for parsing and validating, including adding multiple and custom validation constraints to fields and mapping hierarchical and sequential data. See the [documentation for Forms], the Scaladoc for [play.api.data.Forms], and the Scaladoc for [play.api.data.validation.Constraints] for more information.

## Take Home Points

In this section we saw how to create `Form` objects and use them to parse and validate incoming form data.

We create `Forms` using `Mappings` defined using methods from [play.api.data.Forms].

We extract data from requests using the `bindFromRequest` method of `Form`. Binding may succeed or fail, so we specify behaviours in either case using the `fold` method.

In the next section we will see how to use `Forms` to generate HTML `<form>` and `<input>` tags, pre-populate inputs with text taken from typed Scala data, and report error messages back to the user.

