---
layout: page
title: Calling remote web services
---

# Calling remote web services

In the previous sections we were introduced to `Futures`, and saw how to create *asynchronous actions* to distribute work between threads. In this section we will learn the benefits of *non-blocking I/O* and see Play's non-blocking web services client in action.

## Non-blocking I/O

The biggest sources of latency in web applications tend to be blocking I/O operations such as database queries, file access, and requests to external web services. Asynchronous actions don't eliminate these sources of inefficiency -- they simply help us distribute them between threads.

We can gain a great deal more benefit from asynchronous programming by using *non-blocking I/O* libraries where they are available. Many database libraries in the Java ecosystem are unfortunately blocking. However, Play does include a non-blocking web services client, *Play WS*, that we can use to contact external web services.

## Play WS

As of Play 2.3, the web services client is shipped in a separate JAR from core Play. We can add it to our project by including the following line in `build.sbt`:

~~~ scala
libraryDependencies += ws
~~~

This line of configuration gives us access to the [play.api.libs.ws] package in our code.

[play.api.libs.ws]: https://www.playframework.com/documentation/2.3.x/api/scala/index.html#play.api.libs.ws.package

### Requests and responses

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

 - `WS.url("http://example.com")` creates a [play.api.libs.ws.WSRequestHolder];

 - `WSRequestHolder` contains a set of methods like `withFollowRedirects` and `withRequestTimeout` that allow us to specify parameters and behaviours  before sending the request. These methods return new `WSRequestHolders`, allowing us to chain them together before we actually "hit send";

 - the `get` method of `WSRequestHolder` actually sends the request, returning a `Future` of a [play.api.libs.ws.WSResponse].

The `get` operation is non-blocking -- Play creates a `Future` to hold the eventual result and schedules it for later evaluation when the remote server has responded (or timed out).

The remainder of the code in `index` sets up the chain of operations to execute on the response:

 - extract the `json` from the `WSResponse`;
 - wrap the JSON in an `Ok` result;
 - complete the asynchronous action.

The `index` method returns as soon as the chain of future operations has been set up. Play recycles the current thread for another request.

At some point later, Play receives a response from the remote server and allocates appropriate resources to handle the response and return a result to complete the action.

### Sequencing requests

Let's re-visit our traffic monitoring example from the beginning of the Chapter. We now have enough code to implement a full working solution.

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
def traffic = Action { request =>
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

## Take home points

TODO