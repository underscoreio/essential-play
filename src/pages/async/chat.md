## Extended Exercise: Chat Room Part 4

In this final visit to our chat application we will convert our
single-server codebase to distributed microservice-oriented architecture.
We will separate the auth and chat services into different applications
that talk to one another over HTTP using `Futures` and Play's web services client.

### Directory and Project Structure

The `chapter5-chat` directory in the exercises contains a template application.
Unlike previous exercises, the SBT build is split into four *projects*,
each with its own subdirectory:

 -  the `authApi` project contains an authentication API microservice;

 -  the `chatApi` project contains a chat API microservice;

 -  the `site` project contains a web site that is a client to both microservices;

 -  the `common` project contains code that is shared across the other projects.

The build dependencies and HTTP communication between the projects are illustrated below:

![Project dependencies and HTTP communication](src/pages/async/chat-projects.pdf+svg)

Note that the codebases for the web site and APIs do not depend on one another,
even though they communicate over HTTP when the app is running.
To avoid code duplication, commonalities such as message classes and API client code are
factored out into `common` or re-use throughout the codebase.

In this exercise you will complete parts of the API clients and servers.
We've completed the web site and most of the `common` library for you.

### Using SBT

Because there are four projects in SBT,
you have to specify which one you want to compile, test or run.
You can either do this by specifying the project name as a prefix to the command:

~~~ bash
> authApi/compile
...
~~~

or by using the `project` command to focus on a particular project
before issuing other commands:

~~~ bash
> project chatApi
[info] Set current project to chatApi ↩
       (in build file:/essential-play-code/chapter5-chat/)

[chatApi] $ compile
...
~~~

Running the projects is complicated slightly by the fact that
each microservice has run on a different port on `localhost`.
Play allows you to specify the port via a command line parameter when starting SBT:

~~~ bash
bash$ ./sbt.sh -Dhttp.port=12345
~~~

We've written three shell scripts to hard-code the ports for you:

 - `./run-site.sh` starts the web site on port 9000;
 - `./run-chat-api.sh` starts the chat API on port 9001;
 - `./run-auth-api.sh` starts the auth API on port 9002.

You will need to run each script in a separate terminal window
to boot the complete application.

### Auth API

The auth API has no dependencies on other web services,
so the code is more or less identical to the solution from Chapter 4.
We've already implemented the server for you---you
should be able to run the `run-auth-api.sh` script
and communicate with it on port 9002:

~~~ bash
bash$ curl 'http://localhost:9002/login' \
           --header 'Content-Type: application/json' \
           --data   '{"username":"alice","password":"password1"}'
{
  "type":"LoginSuccess",
  "sessionId":"913d7042-de8a-4f9c-a722-63fb6aa84a79"
}

bash$ curl 'http://localhost:9002/whoami' \
           --header 'Content-Type: application/json' \
           --header 'Authorization: 913d7042-de8a-4f9c-a722-63fb6aa84a79'
{
  "type":"Credentials",
  "username":"alice",
  "sessionId":"913d7042-de8a-4f9c-a722-63fb6aa84a79"
}
~~~

Note that we've removed the `/api` prefix from the routes
because there are no URL naming collisions with the web site.

### Auth API Client

The chat API and web site will communicate with the auth API using a
Scala client defined in the `common` project.
The next step is to finish the code for this client.

Complete the client by filling in the `TODOs` in `AuthServiceClient.scala`.
We've specified the URLs of the API endpoints in the comments.
Use Play JSON to write and read request and response data
and remember to set the `Authorization` header when calling out to `whoami`.

<div class="solution">
Here's an end-to-end implementation of the `login` endpoint.
We simply write the `LoginRequest` as JSON and read the `LoginResponse` back:

~~~ scala
def login(req: LoginRequest): Future[LoginResponse] =
  WS.url(s"http://localhost:9002/login").
    post(Json.toJson(req)).
    flatMap { response =>
      Json.fromJson[LoginResponse](response.json) match {
        case JsSuccess(value, _) =>
          Future.successful(value)

        case error: JsError =>
          Future.failed(new Exception("Bad API response " + error))
      }
    }
~~~

As usual we can tidy the code up by factoring out useful elements.
For example, here's a `parseResponse` method to read a value from the response JSON:

~~~ scala
def login(req: LoginRequest): Future[LoginResponse] =
  WS.url(s"http://localhost:9002/login").
    post(Json.toJson(req)).
    flatMap(parseResponse[LoginResponse](_))

def parseResponse[A](response: WSResponse)(implicit reads: Reads[A]): Future[A] = {
  Json.fromJson[A](response.json) match {
    case JsSuccess(value, _) =>
      Future.successful(value)

    case error: JsError =>
      Future.failed(InvalidResponseException(response, error))
  }
}

case class InvalidResponseException(
  response: WSResponse,
  jsError: JsError
) extends Exception(s"BAD API response:\n${response.json}\n${jsError}")
~~~

The `whoami` endpoint is trivial with our `parseResponse` helper:

~~~ scala
def whoami(sessionId: String): Future[WhoamiResponse] =
  request(s"http://localhost:9002/whoami").
    withHeaders("Authorization" -> sessionId).
    get().
    flatMap(parseResponse[WhoamiResponse](_))
~~~
</div>

We've defined the client in the `common` project to make it available
on the classpath for the chat API and the web site.
Let's look at the chat API next.

### Chat API

The majority of the chat API is in `ChatApiController.scala`.
We've included an `authClient` at the top of the file to authenticate users.

Complete each action. Use `authClient` to do any authentication and
`ChatService` to fetch and post messages.
Because `authClient` is asynchronous, you'll need to use `Futures` and `Action.async`.


<div class="solution">
Let's look at the `messages` endpoint first.
The first thing we have to do is call the `whoami` method in the auth service,
which we previously did using the `withAuthenticatedUser` helper.
Now that the auth service is asynchronous, we have to reimplement this helper.

Here's a prototype implementation that substitutes `Result` for `Future[Result]` in the code:

~~~ scala
def withAuthenticatedUser
    (request: Request[AnyContent])
    (func: LoginResponse => Future[Result]): Future[Result] =
  request.headers.get("Authorization") match {
    case Some(sessionId) =>
      authClient.whoami(sessionId)

    case None =>
      Future.successful(SessionNotFound("NoSessionId"))
  }
~~~

Like many of our previous helper functions,
this implementation makes inflexible assumptions about the return type of `func`.
Ideally we'd like a helper that returns a `LoginResponse` and allows the
caller to make decisions about what to do with it.
We can do this by returning a `Future[LoginResponse]`
and allowing the caller to use `map` or `flatMap` to sequence the next operations:

~~~ scala
def authorization(request: Request[AnyContent]): Future[LoginResponse] =
  request.headers.get("Authorization") match {
    case Some(sessionId) =>
      authClient.whoami(sessionId)

    case None =>
      Future.successful(SessionNotFound("NoSessionId"))
  }
~~~

The `messages` and `chat` actions can be implemented using a combination of
`authorization`, the `map` method, and our previous `withRequestJsonAs` helper:

~~~ scala
def messages = Action.async { request =>
  authorization(request) map {
    case Credentials(sessionId, username) =>
      Ok(Json.toJson(MessagesSuccess(ChatService.messages)))

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(MessagesUnauthorized(sessionId)))
  }
}
~~~

~~~ scala
def chat = Action.async { request =>
  authorization(request) map {
    case Credentials(sessionId, username) =>
      withRequestJsonAs[ChatRequest](request) { postReq =>
        Ok(Json.toJson(ChatSuccess(ChatService.chat(
          username,
          postReq.text))))
      }

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(ChatUnauthorized(sessionId)))
  }
}
~~~
</div>

You should be able to run the completed API with `run-chat-api.sh`
and talk to it on port 9001 using `curl`.
Remember to start the auth API in a second terminal as well:

~~~ bash
bash$ curl 'http://localhost:9002/login' \
           --header 'Content-Type: application/json' \
           --data   '{"username":"alice","password":"password1"}'
{
  "type":"LoginSuccess",
  "sessionId":"913d7042-de8a-4f9c-a722-63fb6aa84a79"
}

bash$ curl 'http://localhost:9001/message' \
           --header 'Content-Type: application/json' \
           --header 'Authorization: 913d7042-de8a-4f9c-a722-63fb6aa84a79' \
           --data '{"text":"First post!"}'
{
  "type":"ChatSuccess",
  "message":{"author":"alice","text":"First post!"}
}
~~~

### Chat API Client

The last part of the exercise involves implementing a client for the chat API.
Complete the `TODOs` in `ChatServiceClient.scala` using a similar
approach to the auth API client.

<div class="solution">
Here's a model solution including the helper methods we developed earlier:

~~~ scala
def messages(sessionId: String): Future[MessagesResponse] =
  WS.url(s"http://localhost:9001/messages").
    withHeaders("Authorization" -> sessionId).
    get().
    flatMap(parseResponse[MessagesResponse](_))

def chat(sessionId: String, chatReq: ChatRequest): Future[ChatResponse] =
  WS.url(s"http://localhost:9001/messages").
    withHeaders("Authorization" -> sessionId).
    post(Json.toJson(chatReq)).
    flatMap(parseResponse[ChatResponse](_))
~~~
</div>

### Putting it All Together

The refactored web site uses the two API clients
instead of calling the chat and auth services directly.
Most of the code is identical to Chapter 3 so we won't make you rewrite it.
Check `ChatController.scala` and `AuthController.scala` for the details.

You should be able to start the web site alongside the two APIs using
the `run-site.sh` script. Watch the console for HTTP traffic on the APIs
as you navigate around the web site.

Congratulations---you have implemented a complete, microservice-driven web application!
