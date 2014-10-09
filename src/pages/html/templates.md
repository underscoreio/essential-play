---
layout: page
title: Twirl Templates
---

# Twirl Templates

Play uses a templating language called *Twirl* to generate HTML. Twirl templates are a JSP- or PHP-like server-side templating language resembling plain HTML content enriched with dynamic Scala expressions. Triwl templates are compiled to type-safe Scala functions for easy use from regular code.

## A First Template

Here is an example template -- `app/views/helloWorld.scala.html` -- that generates a complete *hello world* wehb page:

~~~ html
@(name: String)

<html>
  <head>
    <title>Hello @name!</title>
  </head>

  <body>
    <p>Hello there, @name.</p>
  </body>
</html>
~~~

The first line of the template describes the *template parameters* -- the format is an `@` sign followed a set of Scala method parameters. The remainder of the template is plain HTML containing dynamic parameters of the form `@expression`. The compiled Scala function is of the form:

~~~ scala
package views.html

import play.twirl.api.Html

object helloWorld {
  def apply(name: String): Html = {
    // ...
  }
}
~~~

## Filenames and Classnames

Templates should be placed the `app/views` folder and given filenames ending in `.scala.html`. Their compiled forms are accessible as singleton objects in the `views.html` package. Here are some examples:

|----------------------------------------+----------------------------------------|
| Template file name                     | Scala object name                      |
|----------------------------------------+----------------------------------------|
| `views/helloWorld.scala.html`          | `views.html.helloWorld`                |
| `views/user/loginForm.scala.html`      | `views.html.user.loginForm`            |
| `views/foo/bar/baz.scala.html`         | `views.html.foo.bar.baz`               |
|=================================================================================|
{: .table .table-bordered .table-responsive }

Play knows how to take template return values and turn them into content for `Results`. This makes it very easy to use the template from our `Actions`:

~~~ scala
def index = Action { request =>
  Ok(views.html.helloWorld("Dave"))
}
~~~

## Parameters and Expressions

Twirl templates are just Scala functions. They can have any number of parameters of arbitrary types, and even support features such as default parameter values and multiple/implicit parameter lists.

The body of a Twirl template is compiled to a giant expression that appends all of the static and dynamic components into a single `Html` object. Dynamic parameters are *escaped* to eliminate cross-site scripting vulnerabilities.

Twirl is capable of handling parameters of a variety of types using pattern matching at runtime to convert them to HTML:

 - simple values such as `Strings`, `Ints` and `Booleans` are escaped and inserted into the page;
 - `Seqs` generate content for every item (no delimiter);
 - `Arrays` and Java collections are handled similarly;
 - `Optional` values generate regular content when full and no content when empty.

## Expression Syntax

Twirl also understands various syntactic forms inspired by Scala expressions. Here is a brief synopsis -- for more information see the [Play documentation on template syntax].

[Play documentation on template syntax]: https://www.playframework.com/documentation/2.3.x/ScalaTemplates

Dynamic expressions are prefixed using the `@` character. We don't need to indicate the end of an expression -- Twirl attempts to automatically work out where the Scala code ends and HTML begins:

~~~ html
Hello @name.toUpperCase!
~~~

Twirl occasionally has difficulty determining where dsynamic code ends and static content begins. If this is a problem we can use parentheses or braces to delimit the dynamic content:

~~~ html
The answer is @(a + b).

The answer is @{
  val a = 1
  val b = 2
  a + b
}.
~~~

Method calls can be written as usual. Twirl treats code between parentheses as Scala:

~~~ html
<p>@myMethod(a, b, c)</p>
~~~

Calls to methods of one parameter can be written using braces instead. Twirl treats arguments in braces as HTML, although function parameters still work as expected:

~~~ html
<ul>
  @myList.map { item =>
    <li>@item</li>
  }
</ul>
~~~

Twirl supports conditionals. If we delimit the true and false arms using braces, Twirl treats them as HTML:

~~~ html
<p>
  @if(a > b) {
    <em>looks like @a was greater than @b</em>
  } else {
    <em>looks like @a wasn't greater than @b</em>
  }
</p>
~~~

Match expressions are supported. Twirl treats the right-hand-sides of case clauses as Scalaa *unless* they are surrounded by case clauses:

~~~ html
<p>
  @myList match {
    case Nil      =>
      "the list is empty"

    case a :: Nil =>
      "the list has one element"  + a

    case a :: b   => {
      <em>the list has many elements: @a, and @(b.lenth) others</em>
    }
  }
</p>
~~~

For-comprehensions are supported. The `yield` keyword is implicitly assumed:

~~~ html
<ul>
  @for(item <- myList) {
    <li>@item</li>
  }
</ul>
~~~

Because Twirl templates compile to functions, we can call one template from another to insert or wrap content:

<div class="row">
<div class="col-sm-6">
In `app/views/layout.scala.html`:

~~~ html
@(title: String)(body: Html)

<html>
  <head><title>@title</title></head>
  <body>@body</body>
</html>
~~~
</div>

<div class="col-sm-6">
In `app/views/helloWorld.scala.html`:

~~~ html
@(name: String)

@layout("Hello " + name) {
  <p>Hello there, @name.</p>
}
~~~
</div>
</div>

## Helper Functions

Twirl provides a method `defining` as a means of aliasing a Scala expression as a single identifier:

~~~ html
<p>
  @defining(a + b) { ans =>
    The answer is @ans
  }
</p>
~~~

Play also provides a variety of pre-defined templates in the [views.html.helper] package. We will discuss some of these in the next section.

[views.html.helper]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.package

## Take Home Points

*Twirl templates* are the standard way of creating HTML in Play.

Template files should be placed in the `app/views` folder and have the filename extension `.scala.html`.

Templates are compiled to singleton Scala function objects accessible from the `views.html` package.

Template functions accept whatever parameters we define and return instances of [play.twirl.api.Html]. These return values can be inserted into the `Results` we return from our `Actions`. Play automatically sets the `Content-Type` for us.