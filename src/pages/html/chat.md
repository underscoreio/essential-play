## Extended Exercise: Chat Room Part 2

It's time to revisit our extended exercise from Chapter 2
armed with our new-found knowledge of HTML and web forms.

In the `chapter3-chat` directory in the exercises you will find
updated source code for the internet chat application.
We've included the relevant parts of the solution from Chapter 2
and created new `TODOs` in `ChatController.scala` and
`AuthController.scala`.

### The Login Page

Start by implementing `loginForm`, `login`, and `submitLogin` in `AuthController`.
Use `AuthService` to check the incoming form data.
Keep displaying the login form until the user enters correct credentials.
When the user logs in successfully, use `loginRedirect`
to redirect to `ChatController.index` and set a session cookie.

<div class="solution">
Let's start with `loginForm`, which maps incoming form data to `LoginRequest` messages:

~~~ scala
val loginForm = Form(mapping(
  "username" -> nonEmptyText,
  "password" -> nonEmptyText
)(LoginRequest.apply)(LoginRequest.unapply))
~~~

The `login` endpoint simply passes an empty `loginForm` to a template:

~~~ scala
def login = Action { request =>
  Ok(views.html.login(loginForm))
}
~~~

We won't recreate the complete HTML here, suffice to say that it
accepts a `Form` as a parameter and uses Play's form helpers to render a `<form>` tag:

~~~ scala
@(loginForm: Form[services.AuthServiceMessages.LoginRequest])

...

@helper.form(action = routes.AuthController.submitLogin) {
  @helper.inputText(
    loginForm("username"),
    '_label -> "Username",
    'class -> "form-control"
  )
  @helper.inputPassword(
    loginForm("password"),
    '_label -> "Password",
    'class -> "form-control"
  )
  <button class="btn btn-primary" type="submit">OK</button>
}
~~~

The `submitLogin` action (which is defined as a POST route in the `routes` file)
parses the incoming request data using `loginForm` and either redirects the user
or redisplays the same page with error messages:

~~~ scala
def submitLogin = Action { implicit request =>
  val form = loginForm.bindFromRequest()

  form.fold(
    hasErrors = { form: Form[LoginRequest] =>
      views.html.login(form)
    },
    success = { loginReq: LoginRequest =>
      AuthService.login(loginReq) match {
        case res: LoginSuccess =>
          Redirect(routes.ChatController.index).
            withSessionCookie(res.sessionId)

        case res: UserNotFound =>
          BadRequest(views.html.login(addLoginError(form)))

        case res: PasswordIncorrect =>
          BadRequest(views.html.login(addLoginError(form)))
      }
    }
  )
}

def addLoginError(form: Form[LoginRequest]) =
  form.withError("username", "User not found or password incorrect")
~~~

This code demonstrates the elegance of modelling
service requests and responses as families of case classes and sealed traits.
We simply provide mappings to and from HTML form data,
call the relevant service methods, and pattern match on the results.
</div>

### The Chat Page

Now implement a simple `ChatController.index` that checks
whether the user is logged in and returns a list of `Messages` from `ChatService`.
Use the `withAuthenticatedUser` helper to check the login.

<div class="solution">
The initial implementation of `index` is straightforward---`withAuthenticatedUser`
does most of the work for us:

~~~ scala
def index = Action { implicit request =>
  withAuthenticatedUser(request) { creds =>
    Ok(views.html.chatroom(ChatService.messages))
  }
}
~~~

A minimal `chatroom` template takes a `Seq[Message]` as a parameter and
renders a `<ul>` of messages:

~~~ html
@(messages: Seq[services.ChatServiceMessages.Message],
  chatForm: Form[controllers.ChatController.ChatRequest])

...

<ul>
  @for(message <- messages) {
    <li>@message.author @message.text</li>
  }
</ul>
~~~

See our model solution for the complete HTML.
</div>

Once your web page is working, implement `chatForm` and hook up `submitMessage`.
Include HTML for `chatForm` in your web page to create a complete chat application!

Note that there is a disparity between the information form data
and the information you need to pass to `ChatService`.
`ChatService.chat` takes two parameters:
the `author` of the message and the `text` to post.
The `text` needs to come from the web form but the `author`
can be extracted from the user's authenticated credentials.

<div class="solution">
`chatForm` only needs to collect the message text from the user.
Here's a minimal implementation that reads a single `String`:

~~~ scala
val chatForm: Form[String] =
  Form("text" -> nonEmptyText)
~~~

Even though this minimal implementation will suffice,
it's not a bad idea to create an explicit type
for the data we want to read from the form.
This improves the type-safety of our codebase
and makes it easier to add extra fields in the future.
Here's an alternate implementation of `chatForm`
that wraps the incoming text in a `ChatRequest`:

~~~ scala
case class ChatRequest(text: String)

val chatForm = Form(mapping(
  "text" -> nonEmptyText
)(ChatRequest.apply)(ChatRequest.unapply))
~~~

The `submitMessage` action checks the user is logged in
and uses the `Credentials` from `AuthService` to
provide the `author` for the call to `ChatService.chat`:

~~~ scala
def submitMessage = Action { implicit request =>
  withAuthenticatedUser(request) { creds =>
    chatForm.bindFromRequest().fold(
      hasErrors = { form: Form[ChatRequest] =>
        Ok(views.html.chatroom(ChatService.messages, form))
      },
      success = { chatReq: ChatRequest =>
        ChatService.chat(creds.username, chatReq.text)
        Ok(views.html.chatroom(ChatService.messages, chatForm))
      }
    )
  }
}
~~~

Finally, we have to add a second `Form` parameter to our `template`:

~~~ html
@(messages: Seq[services.ChatServiceMessages.Message],
  chatForm: Form[controllers.ChatController.ChatRequest])

...

@helper.form(action = routes.ChatController.submitMessage) {
  @helper.inputText(
    chatForm("text"),
    '_label -> "Write a message...",
    'class -> "form-control"
  )
  <button class="btn btn-primary" type="submit">OK</button>
}
~~~

The model solution adds a helper method to simplify calling the view.
The user passes in a `Form` and the helper grabs the `Messages`
from `ChatService`:

~~~ scala
private def chatRoom(form: Form[ChatRequest] = chatForm): Result =
  Ok(views.html.chatroom(ChatService.messages, form))
~~~
</div>
