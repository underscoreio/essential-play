## Extended Exercise: Chat Room Part 3

Let's continue our extended exercise by adding a REST API to our chat application.

The `chapter4-chat` directory in the exercises contains a model solution
to the exercise at the end of Chapter 3. We've added two controllers
and four actions to support a REST API:

~~~
POST /api/login    controllers.AuthApiController.login
GET  /api/whoami   controllers.AuthApiController.whoami

GET  /api/message  controllers.ChatApiController.messages
POST /api/message  controllers.ChatApiController.chat
~~~

### Overview of the API

All endpoints accept and return JSON data:

 - `AuthApiController.login` accepts a posted `LoginRequest` and returns a `LoginResponse`
   containing the user's `sessionId`;
 - `AuthApiController.whoami` returns a `WhoamiResponse`
   containing the user's `Credentials`;
 - `ChatApiController.messages` returns a `MessagesResponse`
   containing the `Messages` posted so far;
 - `ChatApiController.chat` accepts a `ChatRequest` and returns a `ChatResponse`
   containing the posted `Message`.

See `ChatServiceMessages.scala` and `AuthServiceMessages.scala` for
a complete description of the request and response messages.

All endpoints except for `login` require authorization,
which is supplied via the standard HTTP `Authorization` header.
The client calls `login` and retrieves a `LoginSuccess` in response:

~~~ bash
bash$ curl 'http://localhost:9000/api/login' \
           --header 'Content-Type: application/json' \
           --data   '{"username":"alice","password":"password1"}'
{
  "type":"LoginSuccess",
  "sessionId":"fc8cfcb2-a758-495c-8708-613ac3ff2a99"
}
~~~

The `sessionId` field from the `LoginSuccess` is then passed
as `Authorization` in requests to the other endpoints:

~~~ bash
bash$ curl 'http://localhost:9000/api/message' \
           --header 'Content-Type: application/json' \
           --header 'Authorization: fc8cfcb2-a758-495c-8708-613ac3ff2a99' \
           --data '{"text":"First post!"}'
{
  "type":"ChatSuccess",
  "message":{"author":"alice","text":"First post!"}
}
~~~

~~~ bash
bash$ curl 'http://localhost:9000/api/message' \
           --header 'Content-Type: application/json' \
           --header 'Authorization: fc8cfcb2-a758-495c-8708-613ac3ff2a99' \
           --data '{"text":"Second post!"}'
{
  "type":"ChatSuccess",
  "message":{"author":"alice","text":"Second post!"}
}
~~~

~~~ bash
bash$ curl 'http://localhost:9000/api/message' \
           --header 'Authorization: fc8cfcb2-a758-495c-8708-613ac3ff2a99'
{
  "type":"MessagesSuccess",
  "messages":[
    {"author":"alice","text":"First post!"},
    {"author":"alice","text":"Second post!"}
  ]
}
~~~

The client can use the `whoami` endpoint to retrieve the
identity of the authorized user:

~~~ bash
bash$ curl 'http://localhost:9000/api/whoami' \
           --header 'Content-Type: application/json' \
           --header 'Authorization: fc8cfcb2-a758-495c-8708-613ac3ff2a99'
{
  "type":"Credentials",
  "username":"alice",
  "sessionId":"fc8cfcb2-a758-495c-8708-613ac3ff2a99"
}
~~~

### The *login* Endpoint

Start by completing the `AuthApiController.login` action.
The new action is analogous to `AuthController.login` from Chapter 3,
except that it sends and receives JSON instead of form data and HTML.

We've implemented JSON `Formats` for `LoginRequest` and `LoginResponse`,
so reading and writing JSON should be easy.
However, you will have to handle several error scenarios:

1. the request body cannot be parsed as JSON;
2. the request JSON cannot be read as a `LoginRequest`;
3. the `LoginRequest` contains an invalid username/password.

In the first two scenarios you should create a custom JSON object
representing the error and return it in a `BadRequest` `Result`.
Errors in the third scenario are covered by the `LoginResponse` data type:
simply serialize the result and return it to the client.

<div class="solution">
Here's a complete implementation of `login`:

~~~ scala
def login = Action { request =>
  request.body.asJson match {
    case Some(json) =>
      Json.fromJson[LoginRequest](json) match {
        case JsSuccess(loginReq, _) =>
          AuthService.login(loginReq) match {
            case loginRes: LoginSuccess =>
              Ok(Json.toJson(loginRes))

            case loginRes: UserNotFound =>
              BadRequest(Json.toJson(loginRes))

            case loginRes: PasswordIncorrect =>
              BadRequest(Json.toJson(loginRes))
          }

        case err: JsError =>
          BadRequest(ErrorJson(err))
      }

    case None =>
      BadRequest(JsError(JsPath, "No JSON specified"))
  }
}
~~~

We can reduce the code significantly by introducing a helper method
to parse the request body and handle missing / malformed JSON:

~~~ scala
def withRequestJsonAs[A: Reads]
      (request: Request[AnyContent])
      (func: A => Result): Result =
  request.body.asJson match {
    case Some(json) =>
      Json.fromJson[A](json) match {
        case JsSuccess(req, _) =>
          func(req)

        case err: JsError =>
          BadRequest(ErrorJson(err))
      }

    case None =>
      BadRequest(JsError(JsPath, "No JSON specified"))
  }
~~~

With this helper the `login` action becomes much more readable:

~~~ scala
def login = Action { request =>
  withRequestJsonAs[LoginRequest](request) { req =>
    AuthService.login(req) match {
      case res: LoginSuccess =>
        Ok(Json.toJson(res))

      case res: UserNotFound =>
        BadRequest(Json.toJson(res))

      case res: PasswordIncorrect =>
        BadRequest(Json.toJson(res))
    }
  }
}
~~~
</div>

### The *whoami* Endpoint

Complete this endpoint as follows:

1. extract the value of the `Authorization` header;
2. pass it to `AuthService.whoami`;
3. serialize the result as JSON and return it to the client.

You will have to handle any missing/invalid `Authorization` headers
by sending a custom JSON error to the client in an appropriate `Result`.

<div class="solution">
Our `withAuthenticatedUser` helper from Chapter 2 comes in useful here.
Here's complete end-to-end code for the endpoint:

~~~ scala
def whoami = Action { request =>
  withAuthenticatedUser(request) {
    case res: Credentials     => Ok(Json.toJson(res))
    case res: SessionNotFound => NotFound(Json.toJson(res))
  }
}
~~~
</div>

### The *messages* and *chat* Endpoints

At this point, completing `ChatApiController` should be trivial.
The behaviour is analogous to `ChatController` from Chapter 3
except that it grabs the session ID from the `Authorization` header
instead of from a cookie.

<div class="solution">
`withAuthenticatedUser` makes defining these endpoints straightforward:

~~~ scala
def messages = Action { request =>
  withAuthenticatedUser(request) {
    case Credentials(sessionId, username) =>
      Ok(Json.toJson(MessagesSuccess(ChatService.messages)))

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(MessagesUnauthorized(sessionId)))
  }
}
~~~

~~~ scala
def chat = Action { request =>
  withAuthenticatedUser(request) {
    case Credentials(sessionId, username) =>
      withRequestJsonAs[ChatRequest](request) { postReq =>
        val message = ChatService.chat(username, postReq.text)
        Ok(Json.toJson(ChatSuccess(message)))
      }

    case SessionNotFound(sessionId) =>
      Unauthorized(Json.toJson(ChatUnauthorized(sessionId)))
  }
}
~~~
</div>
