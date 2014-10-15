---
layout: page
title: Generating Form HTML
---

# Generating Form HTML

In the previous section we saw how we can use `Forms` to parse incoming response data. In this section, we will look at the opposite side of the form-handling coin, generating HTML.

## Forms and Inputs

Play has several built-in helpers for generating `<form>` and `<input>` tags in the [views.html.helper] package. To use these we must pass a `Form` to a template as a parameter:

~~~ scala
@(catForm: Form[Cat])

@helper.form(action = routes.CatController.submitCatForm) {
  @helper.inputText(catForm("name"))
  @helper.inputText(catForm("born"))
  @helper.checkbox(catForm("likesTuna"))
  <button type="submit">Go cats!</button>
}
~~~

If we place this file in `app/views/catFormTemplate.scala.html`, we can invoke it as follows:

~~~ scala
Ok(views.html.catFormTemplate(catForm))
~~~

Let's look at the generated HTML:

~~~ html
<form action="/cat" method="POST">
  <dl id="name_field">
    <dt><label for="name">name</label></dt>
    <dd><input type="text" id="name" name="name" value="" /></dd>
  </dl>
  <dl id="born_field">
    <dt><label for="born">born</label></dt>
    <dd><input type="text" id="born" name="born" value="" /></dd>
    <dd class="info">Numeric</dd>
  </dl>
  <dl id="likesTuna_field">
    <dt><label for="likesTuna">likesTuna</label></dt>
    <dd><input type="checkbox" id="likesTuna" name="likesTuna" value="true" /></dd>
    <dd class="info">format.boolean</dd>
  </dl>
  <button type="submit">Go cats!</button>
</form>
~~~

The basic output contains a `<form>` element and an `<input>` and `<label>` for each field, together with hints on which fields are numeric and boolean.

Note the `format.boolean` error message -- an uninternationalized message that has crept through. We can replace this placeholder text by [internationalizing] our application.

[views.html.helper]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.package
[internationalizing]: https://www.playframework.com/documentation/2.3.x/ScalaI18N

## Pre-Filling Forms

Sometimes we want to pre-fill a `Form` with data taken from a database. We can do this with the `fill` method, which returns a new `Form` filled with input values:

~~~ scala
val populatedForm = catForm.fill(Cat("Garfield", 1978, true))
val populatedHtml = views.html.catFormTemplate(populatedForm))
~~~

The `<inputs>` in the `populatedHtml` here have their `value` attributes set to appropriate starting values.

## Displaying Validation Errors

If we use our template with a form that contains parsing or validation errors, the resulting HTML contains error messages telling the user what they did wrong:

~~~ scala
val badData = Map(
  "name"      -> "Cat",
  "born"      -> "unknown",
  "likesTuna" -> "maybe"
)

catForm.bind(badData).fold(
  (errorForm: Form[Cat]) => BadRequest(views.html.catFormTemplate(errorForm)),
  (cat: Cat) => Redirect("/")
)
~~~

The resulting HTML contains extra `<dd class="error">` tags describing the errors:

~~~ html
<form action="/cat" method="POST">
  <dl class=" " id="catname_field">
    <dt><label for="catname">Cat name</label></dt>
    <dd><input type="text" id="catname" name="name" value="Cat"></dd>
    <dd class="info">Enter the name of your cat</dd>
  </dl>
  <dl class=" error" id="born_field">
    <dt><label for="born">born</label></dt>
    <dd><input type="text" id="born" name="born" value=""></dd>
    <dd class="error">Numeric value expected</dd>
    <dd class="info">Numeric</dd>
  </dl>
  <dl class=" error" id="likesTuna_field">
    <dt><label for="likesTuna">likesTuna</label></dt>
    <dd><input type="checkbox" id="likesTuna" name="likesTuna" value="true"></dd>
    <dd class="error">error.boolean</dd>
    <dd class="info">format.boolean</dd>
  </dl>
  <button type="submit">Go cats!</button>
</form>
~~~

## Customising the HTML

We can customise simple things by passing extra arguments to `inputText` and `checkbox`. For example:

<div class="row">
<div class="col-sm-6">
Twirl code:

~~~ scala
@helper.inputText(
  catForm("name"),
  'id     -> "catname",
  '_label -> "Cat name",
  '_help  -> "Enter the name of your cat"
)
~~~
</div>

<div class="col-sm-6">
Resulting HTML:

~~~ scala
<dl id="catname_field">
  <dt><label for="catname">Cat name</label></dt>
  <dd><input type="text" id="catname" name="name" value=""></dd>
  <dd class="info">Enter the name of your cat</dd>
</dl>
~~~
</div>
</div>

Extra parameters are specified as `Symbol -> String` pairs. By default they place or replace attributes on the `<input>` elements. Certain special arguments, all of which start with `_`, change the HTML in other ways. See the Play [documentation on field constructors] for a complete list.

[documentation on field constructors]: https://www.playframework.com/documentation/2.3.x/

<div class="callout callout-warning">
#### Advanced: Custom Field Constructors

We can use a *custom field constructor* to change the general patterns used to generate HTML. For example, we can generate Twitter Bootstrap compatible HTML by adding the following to the top of our template, right below the method definition:

~~~ html
@import helper.twitterBootstrap._
~~~

The effect on the generated HTML is quite pronounced:

~~~ html
<form action="/cat" method="POST">
  <div class="clearfix" id="name_field">
    <label for="catname">name</label>
    <div class="input">
      <input type="text" id="catname" name="name" value="Cat">
      <span class="help-inline"></span>
    </div>
  </div>
  <div class="clearfix  error" id="born_field">
    <label for="born">born</label>
    <div class="input">
      <input type="text" id="born" name="born" value="unknown">
      <span class="help-inline">Numeric value expected</span>
      <span class="help-block">Numeric</span>
    </div>
  </div>
  <div class="clearfix  error" id="likesTuna_field">
    <label for="likesTuna">likesTuna</label>
    <div class="input">
      <input type="checkbox" id="likesTuna" name="likesTuna" value="true">
      <span class="help-inline">error.boolean</span>
      <span class="help-block">format.boolean</span>
    </div>
  </div>
  <button type="submit">Go cats!</button>
</form>
~~~

We can even define our own field constructors to completely customise our HTML. See the [documentation on field constructors] for more information.

[documentation on field constructors]: https://www.playframework.com/documentation/2.3.x/
</div>

## Take Home Points

`Forms` can be used to generate HTML as well as parse request data.

There are numerous helpers in the [view.html.helpers] package that we can use in our templates.

The HTML we generate contains values and error messages as well as basic form structure. We can use this to generate pre-populated forms or feedback to user error.

We can tweak the generated HTML by passing extra parameters to helpers such as `inputText` and `checkbox`, or make broad sweeping changes by using or creating a custom field constructor.

[views.html.helper]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.package
