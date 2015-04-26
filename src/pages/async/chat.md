## Extended Exercise: Chat Room Part 4

In this final visit to our chat application we will convert our
single codebase to a microservice-oriented architecture.
We'll separate the auth and chat services into different applications
that talk to one another over HTTP.

### Directory and Project Structure

The start-point is in the `chapter5-chat` directory in the exercises.
Unlike previous exercises, the SBT build is split into four *projects*,
each with its own subdirectory:

 -  the `authApi` project contains the auth API microservice;

 -  the `chatApi` project contains the chat API microservice;

 -  the `site` project contains the chat web site,
    which is a client to both microservices;

 -  the `common` project contains code
    that is shared across the other projects.

To specify a project in SBT, prefix the relevant command with the project name and a slash.
For example, to `compile` the `authApi` project do the following:

~~~ bash
bash$ ./sbt.sh
[info] Loading project definition from ↩
       /essential-play-code/chapter5-chat/project
[info] Set current project to root
       (in build file:/essential-play-code/chapter5-chat/)

> authApi/compile
[info] Updating {file:/essential-play-code/chapter5-chat/}authApi...
[info] Done updating.
[info] Compiling 5 Scala sources and 1 Java source to ↩
       /essential-play-code/chapter5-chat/ ↩
         authApi/target/scala-2.11/classes...
~~~

Alternatively you can use the `project` command to switch to a project
and run other commands like `compile` without a prefix:

~~~ bash
dave@Jade ~/d/p/e/chapter5-chat> ./sbt.sh
[info] Loading project definition from ↩
       /essential-play-code/chapter5-chat/project
[info] Set current project to root ↩
       (in build file:/essential-play-code/chapter5-chat/)

> project chatApi
[info] Set current project to chatApi ↩
       (in build file:/essential-play-code/chapter5-chat/)

[chatApi] $ compile
[info] Updating {file:/essential-play-code/chapter5-chat/}chatApi...
[info] Resolving jline#jline;2.12 ...
[info] Done updating.
[info] Compiling 5 Scala sources and 1 Java source to ↩
       /essential-play-code/chapter5-chat/ ↩
         chatApi/target/scala-2.11/classes...
~~~

The web site and API services have to be run on different HTTP ports,
which we have hard-coded as follows:

 - `site` runs on port 9000;
 - `chatApi` runs on port 9001;
 - `authApi` runs on port 9002.

HTTP ports are specified via a command line argument when starting SBT.
We've provided three shell scripts to do this for you:
`run-auth-api.sh`, `run-chat-api.sh', and `run-site.sh`:

~~~ bash
bash$ ./run-auth-api.sh
[info] Loading project definition from ↩
       /essential-play-code/chapter5-chat/project
[info] Set current project to root ↩
       (in build file:/essential-play-code/chapter5-chat/)
[info] Set current project to authApi ↩
       (in build file:/essential-play-code/chapter5-chat/)

--- (Running the application from SBT, auto-reloading is enabled) ---

[info] play - Listening for HTTP on /0:0:0:0:0:0:0:0:9002

(Server started, use Ctrl+D to stop and go back to the console...)
~~~

You will need to run each script in a separate terminal window
to run the complete application.

### Auth API

The server side of the auth API is already implemented in
`authApi/app/controllers/AuthApiController.scala`.
Because the auth API doesn't depend on any external web services,
we are able to reuse the synchronous solution from the end of Chapter 4.
You should be able to run the `run-auth-api.sh` script
and communicate with the auth server on port 9002.
Note that we've removed the `/api` prefix from the routes
because we only have API endpoints running on the server:

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

### Auth API Client

We can communicate with the auth API using `curl`,
but we need a Scala library to call it from the chat API and web site.
We've created a skeleton client in `common/app/clients/AuthServiceClient.scala'
for this purpose.

Complete the client by filling in the *TODOs* in `AuthServiceClient.scala`.
We've given you the URLs in the comments to call the endpoints on the server.
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
        case JsSuccess(value, _) => Future.successful(value)
        case error: JsError      => Future.failed(new Exception("Bad API response " + error))
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
    case JsSuccess(value, _) => Future.successful(value)
    case error: JsError      => Future.failed(InvalidResponseException(response, error))
  }
}

case class InvalidResponseException(response: WSResponse, jsError: JsError)
  extends Exception(s"Invalid response from API:\n${response.json}\n${jsError}")
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

The majority of the chat API is in the file
`chatApi/app/controllers/ChatApiController.scala`.
We've included an `authClient` at the top of the file.
Because `authClient` is asynchronous, you'll need to write the
`messages` and `chat` endpoints using `Action.async`.

Complete each action. Use `authClient` to do any authentication and
`ChatService` to fetch and post messages.

<div class="solution">
Here's an end-to-end implementation of the `messages` endpoint.
First we call `authClient.whoami`, which returns a `Future`.
Because `ChatService` is synchronous,
we can `map` over the `Future` to produce our result.
If `ChatService` was asynchronous, calling it would return a `Future`
and we'd have to use `flatMap` to sequence the two steps:

~~~ scala
def messages = Action.async { request =>
  val authResponse: Future[AuthResponse] =
    request.headers.get("Authorization") match {
      case Some(sessionId) => authClient.whoami(sessionId)
      case None => Future.successful(SessionNotFound("NoSessionId"))
    }

  authResponse map {
    case Credentials(sessionId, username) =>
      Ok(Json.toJson(MessagesSuccess(ChatService.messages)))

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(MessagesUnauthorized(sessionId)))
  }
}
~~~

Once again we can simplify things with a helper method.
The `authorization` method here combines `authClient.whoami`
with the extraction of the `Authorization` header from the `request`:

~~~ scala
def messages = Action.async { request =>
  authorization(request) map {
    case Credentials(sessionId, username) =>
      Ok(Json.toJson(MessagesSuccess(ChatService.messages)))

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(MessagesUnauthorized(sessionId)))
  }
}

def authorization(request: Request[AnyContent]): Future[LoginResponse] =
  request.headers.get("Authorization") match {
    case Some(sessionId) => authClient.whoami(sessionId)
    case None            => Future.successful(SessionNotFound("NoSessionId"))
  }
~~~

The `chat` method is similar.
We use `authorization` to check the user's credentials,
and then `map` over the `Future` to produce a `Result`.
We bring back the `wuthRequestJsonAs` helper from Chapter 4
to simplify reading the JSON from the `request`:

~~~ scala
def chat = Action.async { request =>
  authorization(request) map {
    case Credentials(sessionId, username) =>
      withRequestJsonAs[ChatRequest](request) { postReq =>
        val message = ChatService.chat(username, postReq.text)
        Ok(Json.toJson(ChatSuccess(message)))
      }

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(ChatUnauthorized(sessionId)))
  }
}


private def withRequestJsonAs[A: Reads](request: Request[AnyContent])(func: A => Result): Result =
  request.jsonAs[A] match {
    case JsSuccess(value, _) => func(value)
    case err: JsError        => BadRequest(ErrorJson(err))
  }
~~~
</div>

Once you've completed the chat API, you should be able to
run it with the `run-chat-api.sh` script and talk to it using `curl`.
You'll need to start the auth API in a second terminal
for everything to work properly:

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

Let's finish off the chat part of the codebase
by writing a Scala client for the chat API.
Open up `common/app/clients/ChatServiceClient.scala`
and complete the *TODOs*.

<div class="solution">
The code is very similar to the auth API client.
Here's a model solution including the helper methods
we developed earlier:

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
Check `site/app/controllers/ChatController.scala`
and `site/app/controllers/AuthController.scala` for the details.

You should be able to start the web site alongside the two APIs using
the `run-site.sh` script. Watch the console for HTTP traffic on the APIs
as you navigate around the web site.

Congratulations---over the course of this book you have implemented a
complete, distributed, microservice-driven web application in Play!
