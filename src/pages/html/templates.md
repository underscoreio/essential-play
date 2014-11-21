---
layout: page
title: Twirl Templates
---

## Twirl Templates

Play uses a PHP-like templating language called *Twirl* to generate HTML. Templates are compiled to function objects that can be called directly from regular Scala code. In this section we will look at the Twirl syntax and compilation process.

### A First Template

Twirl templates resemble plain HTML with embedded Scala-like dynamic expressions:

~~~ html
<!-- In app/views/helloWorld.scala.html -->
@(name: String)

<html>
  <head>
    <title>Hello @name</title>
  </head>

  <body>
    <p>Hello there, @name.toUpperCase!</p>
  </body>
</html>
~~~

The first line of the template describes its *parameters*. The format is an `@` sign followed by one or more Scala parameter lists. The rest of the template consists of plain HTML content with dynamic `@expressions`. The expression syntax is based on Scala code with a couple of Twirl-specific tweaks -- read on for details:

~~~ scala
package views.html

import play.twirl.api.Html

object helloWorld {
  def apply(name: String): Html = {
    // ...
  }
}
~~~

### File Names and Compiled Names

We should place templates in the `app/views` folder and give them `.scala.html` filename extensions. Their compiled forms are named based on our filenames and placed in the `views.html` package. Here are some examples:

|---------------------------------------------------------------------------------|
| Template file name                     | Scala object name                      |
|---------------------------------------------------------------------------------|
| `views/helloWorld.scala.html`          | `views.html.helloWorld`                |
| `views/user/loginForm.scala.html`      | `views.html.user.loginForm`            |
| `views/foo/bar/baz.scala.html`         | `views.html.foo.bar.baz`               |
|=================================================================================|
{: .table .table-bordered .table-responsive }

Templates return objects of type [play.twirl.api.Html]. Play knows how to serialize `Html` values in the `Results`. This makes it easy to use templates in our `Actions`:

~~~ scala
def index = Action { request =>
  Ok(views.html.helloWorld("Dave"))
}
~~~

<div class="callout callout-warning">
#### Advanced: Non-HTML Templates

Twirl templates can also be used to generate XML, Javascript, and plain text responses. The folders, packages, and return types vary, but otherwise these templates are identical to the HTML templates discussed here:

|-----------------------------------------------------------------------------------------------------|
| Template type | Source folder | Filename extension | Compiled package | Return type                 |
|-----------------------------------------------------------------------------------------------------|
| HTML          | `app/views`   | `.scala.html`      | `views.html`     | [play.twirl.api.Html]       |
| XML           | `app/views`   | `.scala.xml`       | `views.xml`      | [play.twirl.api.Xml]        |
| Javascript    | `app/views`   | `.scala.js`        | `views.js`       | [play.twirl.api.Txt]        |
| Plain text    | `app/views`   | `.scala.txt`       | `views.txt`      | [play.twirl.api.JavaScript] |
|=====================================================================================================|
{: .table .table-bordered .table-responsive }
</div>



### Parameters and expressions

Twirl templates can have any number of parameters of arbitrary types. They also support features such as default parameter values and multiple/implicit parameter lists:

~~~ html
<!-- user.scala.html -->
@(user: User, showEmail: Boolean = true)(implicit obfuscate: EmailObfuscator)

<ul>
  <li>@user.name</li>
  @if(showEmail) {
    <li>@obfuscate(user.email)</li>
  }
</ul>
~~~

The template body is compiled to a single Scala expression that appends all the static and dynamic parts to a single `Html` object. Twirl uses runtime pattern matching to convert embedded expressions to HTML. All expressions are escaped to prevent code injection vulnerabilities:

 - simple values such as `Strings`, `Ints` and `Booleans` yield representative text;
 - `Seqs`, `Arrays` and Java collections yield content for every item (no delimiter);
 - `Optional` values yield text content when full and no content when empty;
 - `Unit` values yield no content.

Twirl embedded expression syntax is inspired by Scala syntax. Here is a brief synopsis -- for more information see Play's [documentation on template syntax].



#### Simple Expressions

Dynamic expressions are prefixed using the `@` character. We don't need to indicate the end of an expression -- Twirl attempts to automatically work out where the Scala code ends and HTML begins:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>Hello, @"Dave".toUpperCase!</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>Hello, DAVE!</p>
~~~
</div>
</div>

#### Wrapped Expressions

Twirl occasionally has difficulty determining where dynamic code ends and static content begins. If this is a problem we can use parentheses or braces to delimit the dynamic content:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>The first answer is @(1 + 2).</p>

<p>The second answer is @{
  val a = 3
  val b = 4
  a + b
}.</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>The first answer is 3.</p>

<p>The second answer is 7.</p>
~~~
</div>
</div>

#### Method Calls

Method calls can be written as usual. Twirl treats parameters between parentheses as Scala:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>The maximum is @math.max(1, 2, 3).</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>The maximum is 3.</p>
~~~
</div>
</div>

Methods of one parameter can be called using braces instead. Twirl parses the parameter between the braces as HTML:

<div class="row">
<div class="col-sm-6">
~~~ html
<ul>
  @(1 to 3).map { item =>
    <li>Item @item</li>
  }
</ul>
~~~
</div>
<div class="col-sm-6">
~~~ html
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
</ul>
~~~
</div>
</div>

#### Conditionals

If we delimit the true and false arms using braces, Twirl treats them as HTML. Otherwise they are treated as Scala code:

<div class="row">
<div class="col-sm-6">
~~~ html
<!-- a = 1000, b = 2000 -->
<p>
  @if(1 > 2) {
    <em>Help! All of maths is wrong!</em>
  } else {
    <em>Phew! Looks like we're ok.</em>
  }
</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p><em>Phew! Looks like we're ok.</em></p>
~~~
</div>
</div>

If we omit the false arm of a Scala conditional, it evaluates to `Unit`. Twirl renders this as empty content:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>Everything is @if(false) { NOT } ok.</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>Eerything is  ok.</p>
~~~
</div>
</div>

#### Match Expressions

If we wrap the right-hand-sides of case clauses in braces, Twirl treats them as HTML content. Otherwise they are treated as Scala code:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>
  @List("foo", "bar", "baz") match {
    case Nil => "the list is empty"
    case a :: b => {
      <em>the list has many elements:
      @a, and @(b.lenth) others</em>
    }
  }
</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>
  <em>the list has mane elements:
  foo, and 2 others</em>
</p>
~~~
</div>
</div>

#### For-Comprehensions

For-comprehensions are supported without the `yield` keyword, which is implicitly assumed in Twirl syntax:

<div class="row">
<div class="col-sm-6">
~~~ html
<ul>
  @for(item <- 1 to 3) {
    <li>Item @item</li>
  }
</ul>
~~~
</div>
<div class="col-sm-6">
~~~ html
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
</ul>
~~~
</div>
</div>

#### Pre-Defined Helpers

Twirl provides a `defining` method as a means of aliasing complex Scala expressions as single identifiers:

<div class="row">
<div class="col-sm-6">
~~~ html
<p>
  @defining(1 + 2 + 3 + 4 + 5) { sum =>
    The answer is @sum.
  }
</p>
~~~
</div>
<div class="col-sm-6">
~~~ html
<p>
  The answer is 15.
</p>
~~~
</div>
</div>

Play also provides a variety of pre-defined templates in the [views.html.helper] package. We will discuss some of these in the next section.

### Nesting Templates

Because Twirl templates compile to Scala functions, we can call one template from another. We can also pass `Html` content from one template to another to create wrapper-style constructions:

<div class="row">
<div class="col-sm-6">
~~~ html
<!-- In app/views/main.scala.html -->
@hello("Dave")

<!-- In app/views/hello.scala.html -->
@(name: String)

@layout("Hello " + name) {
  <p>Hello there, @name.</p>
}

<!-- In app/views/layout.scala.html -->
@(title: String)(body: Html)

<html>
  <head>
    <title>@title</title>
  </head>
  <body>
    @body
  </body>
</html>
~~~
</div>

<div class="col-sm-6">
~~~ html
<html>
  <head>
    <title>Hello Dave</title>
  </head>
  <body>
    <p>Hello there, Dave.</p>
  </body>
</html>
~~~
</div>
</div>

### Take Home Points

We create HTML in Play using a templating language called *Twirl*.

We place Twirl templates in the `app/views` folder and give them the extension `.scala.html`.

Templates are compiled to singleton Scala functions in the `views.html` package.

Template functions accept whatever parameters we define and return instances of [play.twirl.api.Html]. Play understands how to serialize `Html` objects as content within `Results`. It even sets the `Content-Type` for us.

