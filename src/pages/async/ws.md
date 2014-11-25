## Calling Remote Web Services

I/O operations are the biggest sources of latency in web applications. Database queries, file access, and requests to external web services all take orders of magnitude more time than application code running in-memory. Most libraries in the Java and Scala ecosystems use *blocking I/O*, which is as much of a latency problem for asynchronous applications as it is for synchronous ones.

In this section we will look at *non-blocking I/O* -- I/O that *calls us back* when it completes. Application code doesn't need to block waiting for a result, which frees up resources and provides a huge boost to the sbalability of our web applications.

Although non-blocking I/O is gaining in popularity, libraries are still rare in today's Java and Scala ecosystems. Play provides one of the notable Scala examples in the form of its non-blocking web services client, *Play WS*, which is the focus of this section.

<div class="callout callout-info">
*Adding Play WS as a Dependency*

As of Play 2.3, the web services client is shipped in a separate JAR from core Play. We can add it to our project by including the following line in `build.sbt`:

~~~ scala
libraryDependencies += ws
~~~

This line of configuration gives us access to the [`play.api.libs.ws`] package in our code.


</div>

### Using Play WS

Play WS provides a DSL to construct and send requests to remote services. For example:

~~~ scala
import play.api.libs.ws._

def index = Action.async { request =>
  val response: Future[WSResponse] =
    WS.url("http://example.com").
       withFollowRedirects(true).
       withRequestTimeout(5000).
       get()

  val json: Future[JsValue] =
    response.map(_.json)

  val result: Future[Result] =
    json.map(Ok(_))

  result
}
~~~

Let's dissect this line by line:

 - `WS.url("http://example.com")` creates a [`play.api.libs.ws.WSRequestHolder`] -- an object we use to build and send a request;

 - `WSRequestHolder` contains a set of methods like `withFollowRedirects` and `withRequestTimeout` that allow us to specify parameters and behaviours  before sending the request. These methods return new `WSRequestHolders`, allowing us to chain them together before we actually "hit send";

 - the `get` method actually sends the request, returning a `Future` of a [`play.api.libs.ws.WSResponse`].

The `get` operation is non-blocking -- Play creates a `Future` to hold the eventual result and schedules it for later evaluation when the remote server responds (or times out). The remainder of the code in `index` sets up the chain of operations to execute on the response:

 - extract the `json` from the `WSResponse`;
 - wrap the JSON in an `Ok` result;
 - complete the asynchronous action.

The body of the `index` action returns as soon as the chain of `Futures` is set up. Play proceeds to execute each `Future` as its inputs become available, eventually creating a `Result` to send back to the client.


### A Complete Example

Let's re-visit our traffic monitoring example from earlier. We now have enough code to implement a full working solution.

Let's assume that each of our servers has a traffic reporting endpoint:

~~~
GET /traffic
~~~

that returns a simple JSON packet containing a couple of statistics:

~~~ json
{
  "peak": 1000.0,
  "mean": 500.0
}
~~~

Let's implement `getTraffic`. First we'll create a data-type to hold the JSON response:

~~~ scala
case class TrafficData(peak: Double, mean: Double)

object TrafficData {
  implicit val format = Json.format[TrafficData]
}
~~~

Next we implement our `getTraffic` method. This needs to call the remote endpoint, parse the response JSON, and return the `peak` field from the data:

~~~ scala
def getTraffic(hostname: String): Future[Double] = {
  for {
    response <- WS.url(s"http://$url/traffic").get()
  } yield {
    Json.fromJson[TrafficData](response.json) match {
      case JsSuccess(data, _) => data.peak
      case JsError(_)         => 0.0
    }
  }
}
~~~

Our request-sequencing code remains the same:

~~~ scala
def traffic = Action.async { request =>
  val traffic1 = getTraffic("server1")
  val traffic2 = getTraffic("server2")
  val traffic3 = getTraffic("server3")

  for {
    t1 <- traffic1
    t2 <- traffic2
    t3 <- traffic3
  } yield Ok(Json.obj("traffic" -> (t1 + t2 + t3)))
}
~~~

### Take Home Points

*Play WS* is a non-blocking library for calling out to remote web services. Non-blocking I/O is more resource-efficient than blocking I/O, allowing us to place heavier reliance on web services without sacrificingh scalability.

When we send a request, the library returns a `Future[WSResponse]`. We can use methods like `map` and `flatMap` to process the response without blocking, eventually building a `Future[Result]` to return to our downstream client.
