## Extended Exercise: Chat Room Part 1

In addition to the small exercises sprinkled throughout this book,
at the end of each chapter we will revisit an ongoing exercise
to build a larger application consisting of several components.

We will design this application using a set of mechanical design principles
that will allow us to extend it over the course of the book.
We will add a web interface in the next chapter,
a REST API in the chapter after that,
and in the final content chapter we will separate the application
into microservices and distribute them across different servers.

### Application Structure

Our application is a simple internet chat room
that can be split into two sets of services:

 - *Chat services* control the posting and display of messages
   in our chat room;

 - *Authentication services* allow registered users to log in and out
   and check their current identity.

Each service can be split into two layers:

 - a *service layer*, implemented as pure Scala code with no
   knowledge of its environment;

 - a *controller layer* that maps concepts from the service layer
   to/from HTTP.

These two divisions can be illustrated as follows,
with services as vertical cross-sections of the app,
layers as horizontal cross-sections,
and four main singleton objects implementing the functionality:

\makebox[\linewidth]{\includegraphics[width=0.8\textwidth]{src/pages/basics/chat-overview.pdf}}

<div class="figure">
<div class="text-center">
<img src="src/pages/basics/chat-overview.svg" alt="Basic structure of the chat application" />
</div>
</div>

The methods in `ChatService` and `AuthService`
are implemented in a message-passing style,
with one input message and one output message each.
Specifying the arguments as a single input message
will be useful in future chapters for defining mappings
to and from HTTP data types
such as HTML, form data, and JSON objects.

The messages themselves are implemented in
`ChatServiceMessages` and `AuthServiceMessages`.
Some of the messages, notably the `Response` messages,
have several subtypes. For example a `LoginResponse`
may be a `LoginSuccess`, a `UserNotFound`, or a `PasswordIncorrect`.

The controller layer sits between the service layer and the network,
translating strongly typed Scala data to weakly typed HTTP data.
In a production application there may be multiple controllers for each service:
one for a web interface, one for a REST API, and so on.
In this exercise we have a single set of controllers
implemented using a simple plain text protocol
because we don't yet know how to handle HTML pages or form data:

 - most request data is specified in the URL;
 - authentication tokens are submitted using cookies;
 - all response data is returned in plain text.

Note that `Service` objects don't talk to one another directly.
This is a deliberate design decision to support our eventual aim
of distributing the application as a set of microservices.
We run all communication through the `Controllers`,
reducing the number of files we need to touch
to reimplement the internal communcations within the applcation.


### Completing the Exercise

You have two tasks in the exercise:

1.  implement the missing methods in `AuthService` and `ChatService`;
2.  implement the missing actions in `AuthController` and `ChatController`.

We have set up routes for you in `conf/routes`.
We have also set up unit tests for the services and controllers
to help you check your code:

 -  `controllers.ChatControllerSpec`
 -  `controllers.AuthControllerSpec`
 -  `services.ChatServiceSpec`
 -  `services.AuthServiceSpec`

<div class="callout callout-info">
*Test Driven Development*

As with previous exercises we recommend you proceed
by writing code in small chunks. Start with the `Services` files.
Concentrate on one file at a time and run the tests to check your work.

You can run the tests for a single class using the `testOnly` command in SBT.
Use it in watch mode to get fast turnaround as you work:

~~~ bash
[app] $ ~testOnly services.ChatServiceSpec
~~~
</div>

### Service Layer Solutions

In lieu of using an actual database, `ChatService` maintains
an in-memorydata store of messages.
An immutable `Vector` is a good data type for our purposes
because of its efficient iteration and append operations.

The three methods of `ChatService` perform simple operations on the store.
They don't do any authentication checks---we leave these up to `ChatController`:

<div class="solution">
`clear` resets `postedMessages` to an empty `Vector`:

~~~ scala
def clear(): Unit =
  postedMessages = Vector[Message]()
~~~

`messages` returns `postedMessages`. We don't need to worry about exposing
a direct reference to the `Vector` because it is immutable:

~~~ scala
def messages: Seq[Message] =
  postedMessages
~~~

`chat` creates a new `Message`, appends it to the data store,
and returns it:

~~~ scala
def chat(author: String, text: String): Message = {
  val message = Message(author, text)
  postedMessages = postedMessages :+ message
  message
}
~~~
</div>

###

Our substitute for a database in `AuthService` consists of two in-memory
`Maps`:

 - `passwords` stores `Usernames` to `Passwords`
   for all registered users (there is no option to register for a new account);

 - `sessions` stores `SessionIds` and `Usernames`
   for all *currently active* users.

The `Username`, `Password`, and `SessionId` types are all aliases for `String`.
The offer no type safety but they do make the intent clearer in the code.
We could easily replace the type aliases with value classes
in the future if we desired extra type safety.

The `login`, `logout` and `whoami` methods primarily operate on `sessions`:

<div class="solution">
`login` is the most complex method. It checks the credentials in the
`LoginRequest` and returns a `LoginSuccess`, `PasswordIncorrect`,
or `UserNotFound` response as appropriate. If the user is successfully
logged in, the method creates a `SessionId` and caches it in `sessions`
before returning it:

~~~ scala
def login(request: LoginRequest): LoginResponse = {
  passwords.get(request.username) match {
    case Some(password) if password == request.password =>
      val sessionId = generateSessionId
      sessions += (sessionId -> request.username)
      LoginSuccess(sessionId)

    case Some(user) => PasswordIncorrect(request.username)
    case None       => UserNotFound(request.username)
  }
}

def generateSessionId: String =
  java.util.UUID.randomUUID.toString
~~~

`logout` is much simpler because we always expect it to succeed.
If the client passes us a valid `SessionId`, we remove it from `sessions`.
Otherwise we simply noop:

~~~ scala
def logout(sessionId: SessionId): Unit =
  sessions -= sessionId
~~~

Finally, `whoami` searches for a `SessionId` in `sessions` and responds
with a `Credentials` or `SessionNotFound` object as appropriate:

~~~ scala
def whoami(sessionId: SessionId): WhoamiResponse =
  sessions.get(sessionId) match {
    case Some(username) => Credentials(sessionId, username)
    case None           => SessionNotFound(sessionId)
  }
~~~
</div>

### Controller Layer Solutions

`ChatController` wraps each method from `ChatService`
with a method that does two jobs:
translate requests and responses to and from HTTP primitives,
and authenticate each request from the client.

The first thing to do when handling any `Request`
is to check whether the user has authenticated with `AuthController`.
We do this using a help method that extracts a `SessionId` from a cookie,
checks it against `AuthService`,
and passes the extracted `Credentials` to a success function:

~~~ scala
def withAuthenticatedUser ↩
    (request: Request[AnyContent]) ↩
    (func: Credentials => Result): Result =
  request.sessionCookieId match {
    case Some(sessionId) =>
      AuthService.whoami(sessionId) match {
        case res: Credentials     => func(res)
        case res: SessionNotFound => BadRequest("Not logged in!")
      }
    case None => BadRequest("Not logged in!")
  }
~~~

With the bulk of the work done, the `index` and `submitMessage`
methods are trivial to implement:

~~~ scala
def index = Action { request =>
  withAuthenticatedUser(request) { creds =>
    Ok(ChatService.messages.mkString("\n"))
  }
}

def submitMessage(text: String) = Action { request =>
  withAuthenticatedUser(request) { creds =>
    ChatService.chat(creds.username, text)
    Redirect(routes.ChatController.index)
  }
}
~~~

`AuthController` is much simpler than `ChatController`
because we have only chosen to implement an interface to the `login` method
(we'll implement more methods in future chapters).
The `Action` here is simply mapping back and forth
between HTTP data and Scala messages:

~~~ scala
def login(username: Username, password: Password) =
  Action { request =>
    AuthService.login(LoginRequest(username, password)) match {
      case res: LoginSuccess =>
        Ok("Logged in!").withSessionCookie(res.sessionId)

      case res: UserNotFound =>
        BadRequest("User not found or password incorrect")

      case res: PasswordIncorrect =>
        BadRequest("User not found or password incorrect")
    }
  }
~~~

### Exercise Summary

In this extended exercises we have implemented an application
using a simple service-oriented architecture.
We have made a clean split between *service level* code
written in 100% strongly typed Scala,
and *controller level* code to mediate between services and the network.

This two-way split of services and layers is useful for a number of reasons.
It allows us to implement additional controllers on top of the same services,
paving the way towards the eventual development of a REST API.
It also forces us to think of chat and authentication
as separate parts of our application,
paving the way towards distribution as microservices.

APIs and microservices are to be delayed until later in this book, however.
We will revisit the chat application at the end of the next chapter,
armed with a knowledge of HTML and web form processing
and ready to create a full web interface for our application!
