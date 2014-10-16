---
layout: page
title: Generating Form HTML
---

# Generating Form HTML

In the previous section we saw how to use `Forms` to parse incoming request data from the browser. `Forms` also allow us to generate `<form>` tags that help the browser send data to us in the correct format. In this section we'll use `Forms` to generate `<form>` and `<input>` elements and populate them with data and validation errors:

## Forms and Inputs

Play provides several built-in templates in the [views.html.helper] package for generating `<form>` and `<input>` elements. We have to pass these data from our `Form` object, so our first step is to pass this to our own templates:

~~~ scala
@(todoForm: Form[Todo])

@helper.form(action = routes.TodoController.submitTodoForm) {
  @helper.checkbox(todoForm("complete"))
  @helper.inputText(todoForm("name"))
  @helper.inputText(todoForm("priority"))
  <button type="submit">OK</button>
}
~~~

If we place this file in `app/views/todoFormTemplate.scala.html`, we can invoke it as follows:

~~~ scala
Ok(views.html.todoFormTemplate(todoForm))
~~~

Let's look at the generated HTML:

~~~ html
<form action="/todo" method="POST">
  <dl id="name_field">
    <dt><label for="name">name</label></dt>
    <dd><input type="text" id="name"
               name="name" value="" /></dd>
  </dl>
  <dl id="priority_field">
    <dt><label for="priority">priority</label></dt>
    <dd><input type="text" id="priority"
               name="priority" value="" /></dd>
    <dd class="info">Numeric</dd>
  </dl>
  <dl id="complete_field">
    <dt><label for="complete">complete</label></dt>
    <dd><input type="checkbox" id="complete"
               name="complete" value="true" /></dd>
    <dd class="info">format.boolean</dd>
  </dl>
  <button type="submit">OK</button>
</form>
~~~

The basic output contains a `<form>` element and an `<input>` and `<label>` for each field, together with hints on which fields are numeric and boolean.

[views.html.helper]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.package

<div class="callout callout-warning">
#### Advanced: Internationalization

Notice the text `"format.boolean"` in the generated HTML. This is an uninternationalized message that has crept through due to a missing value in Play's default string tables. We can fix the broken message by providing our own [internationalization] for our application. However, this is beyond the scope of this chapter.

[internationalization]: https://www.playframework.com/documentation/2.3.x/ScalaI18N
</div>

## Pre-Filling Forms

Sometimes we want to pre-fill a `Form` with data taken from a database. We can do this with the `fill` method, which returns a new `Form` filled with input values:

~~~ scala
val populatedForm = todoForm.fill(Todo("Start Essential Scala", 1, true))
val populatedHtml = views.html.todoFormTemplate(populatedForm)
~~~

The `<inputs>` in the `populatedHtml` here have their `value` and `checked` attributes set to appropriate starting values:

~~~ html
<form action="/todo" method="POST">
  <dl id="name_field">
    <dt><label for="name">name</label></dt>
    <dd><input type="text" id="name"
               name="name" value="Start Essential Scala" /></dd>
  </dl>
  <dl id="priority_field">
    <dt><label for="priority">priority</label></dt>
    <dd><input type="text" id="priority"
               name="priority" value="1" /></dd>
    <dd class="info">Numeric</dd>
  </dl>
  <dl id="complete_field">
    <dt><label for="complete">complete</label></dt>
    <dd><input type="checkbox" id="complete"
               name="complete" value="true" checked="checked" /></dd>
    <dd class="info">format.boolean</dd>
  </dl>
  <button type="submit">OK</button>
</form>
~~~

## Displaying Validation Errors

If we fail to bind a request in our `Action`, Play calls the failure argument in our call to `Form.fold`. The argument to our failure function is a `Form` containing a complete set of validation error messages. If we pass the `Form` object to our form template, Play will add the error messages to the generated HTML:

~~~ scala
val badData = Map(
  "name"     -> "Todo",
  "priority" -> "unknown",
  "complete" -> "maybe"
)

todoForm.bind(badData).fold(
  (errorForm: Form[Todo]) => BadRequest(views.html.todoFormTemplate(errorForm)),
  (todo: Todo) => Redirect("/")
)
~~~

The resulting HTML contains extra `<dd class="error">` tags describing the errors:

~~~ html
<form action="/todo" method="POST">
  <dl class=" " id="name_field">
    <dt><label for="name">Todo name</label></dt>
    <dd><input type="text" id="name"
               name="name" value="Todo" /></dd>
  </dl>
  <dl class=" error" id="priority_field">
    <dt><label for="priority">priority</label></dt>
    <dd><input type="text" id="priority"
               name="priority" value="unknown" /></dd>
    <dd class="error">Numeric value expected</dd>
  </dl>
  <dl class=" error" id="complete_field">
    <dt><label for="complete">complete</label></dt>
    <dd><input type="checkbox" id="complete"
               name="complete" value="true" /></dd>
    <dd class="error">error.boolean</dd>
    <dd class="info">format.boolean</dd>
  </dl>
  <button type="submit">OK</button>
</form>
~~~

## Customising the HTML

We can tweak the HTML for our inputs by passing extra arguments to `inputText` and `checkbox`:

<div class="row">
<div class="col-sm-6">
Twirl code:

~~~ scala
@helper.inputText(
  todoForm("name"),
  'id     -> "todoname",
  '_label -> "Todo name",
  '_help  -> "Enter the name of your todo"
)
~~~
</div>

<div class="col-sm-6">
Resulting HTML:

~~~ scala
<dl id="todoname_field">
  <dt><label for="todoname">Todo name</label></dt>
  <dd><input type="text" id="todoname" name="name" value=""></dd>
  <dd class="info">Enter the name of your todo</dd>
</dl>
~~~
</div>
</div>

The extra parameters are keyword/value pairs of type `(Symbol, String)`. Most keywords add or replace attributes on the `<input>` element. Certain special keywords starting with an `_` change the HTML in other ways:

 - `'_label` customises the text in the `<label>` element;
 - `'_help` adds a line of help text to the element;
 - `'_id` alters the `id` attribute of the `<dl>` tag (as opposed to the `<input>`).

See the Play [documentation on field constructors] for a complete list of special keywords.

[documentation on field constructors]: https://www.playframework.com/documentation/2.3.x/

<div class="callout callout-warning">
#### Advanced: Custom Field Constructors

Sometimes small tweaks to the HTML aren't enough. We can make comprehensive changes to the HTML structure by specifying a *field constructor* in our template. For example, we can generate Twitter Bootstrap compatible HTML by adding the following to the top of our template, right below the method definition:

~~~ html
@import helper.twitterBootstrap._
~~~

The effect on the generated HTML is quite pronounced:

~~~ html
<form action="/todo" method="POST">
  <div class="clearfix" id="name_field">
    <label for="name">name</label>
    <div class="input">
      <input type="text" id="name" name="name" value="Todo">
      <span class="help-inline"></span>
    </div>
  </div>
  <div class="clearfix  error" id="priority_field">
    <label for="priority">priority</label>
    <div class="input">
      <input type="text" id="priority" name="priority" value="unknown">
      <span class="help-inline">Numeric value expected</span>
      <span class="help-block">Numeric</span>
    </div>
  </div>
  <div class="clearfix  error" id="complete_field">
    <label for="complete">complete</label>
    <div class="input">
      <input type="checkbox" id="complete" name="complete" value="true">
      <span class="help-inline">error.boolean</span>
      <span class="help-block">format.boolean</span>
    </div>
  </div>
  <button type="submit">OK</button>
</form>
~~~

We can even define our own field constructors to completely customise our HTML. See the [documentation on field constructors] for more information.

[documentation on field constructors]: https://www.playframework.com/documentation/2.3.x/
</div>

## Take Home Points

`Forms` can be used to generate HTML as well as parse request data.

There are numerous helpers in the [views.html.helper] package that we can use in our templates, including the following:

 - [views.html.helper.form] generates `<form>` elements from `Form` objects;
 - [views.html.helper.inputText] generates `<input type="text">` elements for specific form fields;
 - [views.html.helper.checkbox] generates `<input type="checkbox">` elements for specific form fields.

The HTML we generate contains values and error messages as well as basic form structure. We can use this to generate pre-populated forms or feedback to user error.

We can tweak the generated HTML by passing extra parameters to helpers such as `inputText` and `checkbox`, or make broad sweeping changes using a custom field constructor.

[views.html.helper]:           https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.package
[views.html.helper.form]:      https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.form$
[views.html.helper.inputText]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.inputText$
[views.html.helper.checkbox]:  https://www.playframework.com/documentation/2.3.x/api/scala/index.html#views.html.helper.checkbox$