## Generating Form HTML

In the previous section we saw how to use `Forms`
to parse incoming request data from the browser.
`Forms` also allow us to generate `<form>` tags
that help the browser send data to us in the correct format.
In this section we'll use `Forms` to generate `<form>` and `<input>` elements
and populate them with data and validation errors:

### Forms and Inputs

Play provides several built-in templates in the [`views.html.helper`] package
for generating `<form>` and `<input>` elements:

~~~ scala
@(todoForm: Form[Todo])

@helper.form(action = routes.TodoController.submitTodoForm) {
  @helper.checkbox(todoForm("complete"))
  @helper.inputText(todoForm("name"))
  @helper.inputText(todoForm("priority"))
  <button type="submit">OK</button>
}
~~~

If we place this file in `app/views/todoFormTemplate.scala.html`,
we can invoke it as follows:

~~~ scala
Ok(views.html.todoFormTemplate(todoForm))
~~~

The generated HTML contains a `<form>` element and
an `<input>` and `<label>` for each field,
together with hints on which fields are numeric and boolean:

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

<div class="callout callout-warning">
*Internationalization*

Notice the text `"format.boolean"` in the generated HTML.
This is an uninternationalized message that has crept through
due to a missing value in Play's default string tables.
We can fix the broken message by providing
our own [internationalization][docs-i18n] for our application.
See the linked documentation for details.
</div>

### Pre-Filling Forms

Sometimes we want to pre-fill a `Form` with data taken from a database.
We can do this with the `fill` method,
which returns a new `Form` filled with input values:

~~~ scala
val populatedForm = todoForm.fill(Todo("Start Essential Scala", 1, true))
val populatedHtml = views.html.todoFormTemplate(populatedForm)
~~~

The `<inputs>` in the `populatedHtml` here
have their `value` and `checked` attributes set to appropriate starting values:

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

### Displaying Validation Errors

If we fail to bind a request in our `Action`,
Play calls the failure argument in our call to `Form.fold`.
The argument to our failure function is a `Form` containing
a complete set of validation error messages.
If we pass the `Form` with errors to our form template,
Play will add the error messages to the generated HTML:

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

### Customising the HTML

We can tweak the HTML for our inputs by passing
extra arguments to `inputText` and `checkbox`:

*Twirl code:*

~~~ scala
@helper.inputText(
  todoForm("name"),
  'id     -> "todoname",
  '_label -> "Todo name",
  '_help  -> "Enter the name of your todo"
)
~~~

*Resulting HTML:*

~~~ scala
<dl id="todoname_field">
  <dt><label for="todoname">Todo name</label></dt>
  <dd><input type="text" id="todoname" name="name" value=""></dd>
  <dd class="info">Enter the name of your todo</dd>
</dl>
~~~

The extra parameters are keyword/value pairs of type `(Symbol, String)`.
Most keywords add or replace attributes on the `<input>` element.
Certain special keywords starting with an `_` change the HTML in other ways:

 - `'_label` customises the text in the `<label>` element;
 - `'_help` adds a line of help text to the element;
 - `'_id` alters the `id` attribute of the `<dl>` tag (as opposed to the `<input>`).

See the Play [documentation on field constructors][docs-field-constructors]
for a complete list of special keywords.

<div class="callout callout-warning">
*Custom Field Constructors*

Sometimes small tweaks to the HTML aren't enough.
We can make comprehensive changes to the HTML structure
by specifying a *field constructor* in our template.
See the [documentation on field constructors][docs-field-constructors] for more information.

[This StackOverflow post][link-using-bootstrap-with-play]
contains information on using a custom field constructor
to generate [Twitter Bootstrap][link-twitter-bootstrap] compatible form HTML.
</div>

### Take Home Points

`Forms` can be used to generate HTML as well as parse request data.

There are numerous helpers in the [`views.html.helper`] package
that we can use in our templates, including the following:

 - [`views.html.helper.form`] generates `<form>` elements from `Form` objects;
 - [`views.html.helper.inputText`] generates `<input type="text">` elements for specific form fields;
 - [`views.html.helper.checkbox`] generates `<input type="checkbox">` elements for specific form fields.

The HTML we generate contains values and error messages as well as basic form structure.
We can use this to generate pre-populated forms or feedback to user error.

We can tweak the generated HTML by passing extra parameters
to helpers such as `inputText` and `checkbox`,
or make broad sweeping changes using a custom field constructor.

### Exercise: A Simple Formality

The `chapter3-todo-form` directory in the exercises
contains an application based on the model solution
to the previous exercise, *Much Todo About Nothing*.

Modify this application to add a form for creating new todo items.
Place the form under the current todo list and
allow the user to label the new todo and optionally imediately mark it complete.

Start by defining a `Form[Todo]`.
Either place the form in `TodoController`
or create a `TodoFormHelpers` trait in a similar vein to `TodoDataHelpers`.
Note that the `Todo` class in the exercise is
different from the example `Todo` class used above.
You will have to update the example field mapping accordingly.

Once your `Form` is compiling, turn your attention to the page template.
Pass a `Form` as a parameter and render the relevant HTML
using the helper methods described above.
Use the pre-defined `TodoController.submitTodoForm` action
to handle the form submission.

Finally, fill out the definition of `TodoController.submitTodoForm`.
Extract the form data from the request, run the validation, and respond appropriately.
If the form is valid, create a new `Todo`, add it to `todoList`,
and redirect to `TodoController.index`.
Otherwise return the form to the user showing any validation errors encountered.

<div class="solution">
The minimal `Form` definition provides mappings for each of the three fields:
`id`, `label`, and `complete`. We use Play's `nonEmptyText` helper
as a shortcut for `text.verifying(nonEmpty)`:

~~~ scala
val todoForm: Form[Todo] = Form(mapping(
  "id"        -> text,
  "label"     -> nonEmptyText,
  "complete"  -> boolean
)(Todo.apply)(Todo.unapply))
~~~

The model solution goes one step beyond this by
defining a custom constraint for the optional UUID-formatted `id` field:

~~~ scala
val uuidConstraint: Constraint[String] = pattern(
  regex = "(?i:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})".r,
  name  = "UUID",
  error = "error.uuid"
)

val todoForm: Form[Todo] = Form(mapping(
  "id"        -> optional(text.verifying(uuidConstraint)),
  "label"     -> nonEmptyText,
  "complete"  -> boolean
)(Todo.apply)(Todo.unapply))
~~~

If the browser submits a form with a malformed `id`, this constraint will pick it up.
The `error.uuid` code is our own invention---it won't appear in a human-friendly format
in the web page if the constraint is violated, but it is fine for debugging purposes.

Here is a minimal template to render this form in HTML.
We've factored the code out into its own file, `todoForm.scala.html`:

~~~ html
@(form: Form[models.Todo])

@helper.form(action = routes.TodoController.submitTodoForm, 'class -> "todo-form") {
  @helper.checkbox(
    form("complete"),
    '_class -> "todo-complete",
    '_label -> "",
    '_help -> ""
  )

  @helper.inputText(
    form("label"),
    '_class -> "todo-label",
    '_label -> "",
    '_help -> "",
    'placeholder -> "Enter a new todo"
  )

  <button type="submit">Create</button>
}
~~~

We don't need to add the `id` field to the HTML
because new `Todos` always have an `id` of `None`.
If we wanted to edit `Todos` as well as create them
we'd have to add a hidden field as follows:

~~~ html
<input type="hidden" name="id" value="@form("id").value">
~~~

We need to update `todoList.scala.html` and `TodoController.renderTodoList`
to pass the `Form` through. Here's `renderTodoList`:

~~~ scala
def renderTodoList(todoList: TodoList, form: Form[Todo]): Html =
  views.html.todoList(todoList, form)
~~~

and here's `todoList.scala.html`:

~~~ html
@(todoList: TodoList, form: Form[models.Todo])

@import models._

@pageLayout("Todo") {
  <h2>My current todos</h2>

  <!-- Render the todo list... -->

  <h2>Add a new todo</h2>

  @todoForm(form)
}
~~~

With this infrastructure in place we can implement `submitTodoForm`:

~~~ scala
def submitTodoForm = Action { implicit request =>
  todoForm.bindFromRequest().fold(
    hasErrors = { errorForm =>
      BadRequest(renderTodoList(todoList, errorForm))
    },
    success = { todo =>
      todoList = todoList.addOrUpdate(todo)
      Redirect(routes.TodoController.index)
    }
  )
}
~~~
</div>

**Extra credit:** If you get the create form working,
as an extended exercise you could try modifying the page
so that every todo item is editable.
You have free reign to decide how to do this---there
are a few options available to you:

 -  You can create separate `Forms` and `Actions` for creating and editing `Todos`.
 You will have to define custom mappings between the `Forms` and the `Todo` class.

 -  You can re-use your existing `Form` and `submitTodoForm` for both purposes.
    You'll have to update the definition of `submitTodoForm` to examine the `id` field
    and see if it was submitted.

See the `solutions` branch for a complete model solution using the second of these approaches.
