## Calling Remote Web Services

I/O operations are the biggest sources of latency in web applications. Database queries, file access, and requests to external web services all take orders of magnitude more time than application code running in-memory. Most libraries in the Java ecosystem (and older libraries in the Scala ecosystem) use *blocking I/O*, which is as much of a latency problem for asynchronous applications as it is for synchronous ones.

In this section we will look at *non-blocking I/O*---I/O that *calls us back* when it completes. Application code doesn't need to block waiting for a result, which frees up resources and provides a huge boost to the scalability of our web applications.

There are several examples of non-blocking database libraries in Scala: [Slick 3][link-slick], [Doobie][link-doobie], and [Reactivemongo][link-reactivemongo] all support asynchronous queries and the streaming of results back into the application. However, in this section we're going to look at something different---calling external web services using Play's non-blocking HTTP client, *Play WS*.

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

 - `WS.url("http://example.com")` creates a [`play.api.libs.ws.WSRequestHolder`]---an object we use to build and send a request;

 - `WSRequestHolder` contains a set of methods like `withFollowRedirects` and `withRequestTimeout` that allow us to specify parameters and behaviours  before sending the request. These methods return new `WSRequestHolders`, allowing us to chain them together before we actually "hit send";

 - the `get` method actually sends an HTTP GET request, returning a `Future` of a [`play.api.libs.ws.WSResponse`].

The `get` operation is non-blocking. Play creates a `Future` to hold the eventual result and schedules it for later evaluation when the remote server responds (or times out). The remainder of the code sets up the chain of operations to transform the response: extract the `json`, wrap it in an `Ok` result, and return it to the user.

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
    Json.fromJson[TrafficData](response.json).fold(
      errors => 0.0,
      traffic => traffic.peak
    )
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

## Exercise: Oh, The Weather Outside is Frightful!

...but this JSON weather data from flyovers of the Interantional Space Station is so delightful!

The `chapter5-weather` directory in the exercises
contains an unfinished application for reporting on weather data from
[openweathermap.com](http://openweathermap.com).

The application will use two API endpoints. The `weather` endpoint ([documented here](http://openweathermap.com/current)) reports current weather data:

~~~ json
bash$ curl 'http://api.openweathermap.org/data/2.5/weather?q=London,uk'
{"coord":{"lon":-0.13,"lat":51.51},"sys":{"type":3,"id":98614, ↩
"message":0.016,"country":"GB","sunrise":1427780233, ↩
"sunset":1427826720},"weather":[{"id":501,"main":"Rain", ↩
"description":"moderate rain","icon":"10d"}],"base":"stations", ↩
"main":{"temp":285.11,"humidity":42,"pressure":1017.4, ↩
"temp_min":282.59,"temp_max":286.55},"wind":{"speed":2.4,"gust":4.4, ↩
"deg":0},"rain":{"1h":2.03},"clouds":{"all":20},"dt":1427814471, ↩
"id":2643743,"name":"London","cod":200}
~~~

and the `forecast` endpoint ([documented here](http://openweathermap.com/forecast)) reports a five day forecast:

~~~ json
bash$ curl 'http://api.openweathermap.org/data/2.5/forecast?q=London,uk'
{"cod":"200","message":0.0388,"city":{"id":2643743,"name":"London", ↩
"coord":{"lon":-0.12574,"lat":51.50853},"country":"GB","population":0, ↩
"sys":{"population":0}},"cnt":28,"list":[{"dt":1427803200, ↩
"main":{"temp":285.48,"temp_min":283.15,"temp_max":285.48, ↩
"pressure":1016.77,"sea_level":1024.63,"grnd_level":1016.77, ↩
"humidity":63,"temp_kf":2.33},"weather":[{"id":802,"main":"Clouds", ↩
"description":"scattered clouds","icon":"03d"} ],"clouds":{"all":48}, ↩
"wind":{"speed":7.81,"deg":293.001},"rain":{"3h":0},"sys":{"pod":"d"}, ↩
"dt_txt":"2015-03-31 12:00:00"},...]}
~~~

The example app includes code to read the responses from these endpoints as instances of `models.Weather` and `models.Forecast` respectively.

Complete the code in `WeatherController.scala` to fetch results from both of these endpoints and combine them using the `report.scala.html` template. Start by completing the `fetchWeather` and `fetchForecast` methods using the `WS` API, and then combine the results in the `report` method.

<div class="solution">
Here's a simple implementation of `fetchWeather` and `fetchForecast`:

~~~ scala
def fetchWeather(location: String): Future[Weather] =
  WS.url(s"http://api.openweathermap.org/data/2.5/weather?q=$location,uk").
    withFollowRedirects(true).
    withRequestTimeout(500).
    get().
    map(_.json.as[Weather])

def fetchForecast(location: String): Future[Forecast] =
  WS.url(s"http://api.openweathermap.org/data/2.5/forecast?q=$location,uk").
    withFollowRedirects(true).
    withRequestTimeout(500).
    get().
    map(_.json.as[Forecast])
~~~

Note that the error handling in the model solution ignores the fact that
the incoming JSON data may be malformed---we rely Play to pick this error up
and serve an HTTP 500 error page.

We can refactor the redundancy in the two methods into a separate method, `fetch`.
Note the `Reads` context bound on the type parameter to `fetch`,
which provides evidence to the compiler that we can read `A` from JSON:

~~~ scala
def fetchWeather(location: String): Future[Weather] =
  fetch[Weather]("weather", location)

def fetchForecast(location: String): Future[Forecast] =
  fetch[Forecast]("forecast", location)

def fetch[A: Reads](endpoint: String, location: String): Future[A] =
  WS.url(s"http://api.openweathermap.org/data/2.5/$endpoint?q=$location,uk").
    withFollowRedirects(true).
    withRequestTimeout(500).
    get().
    map(_.json.as[A])
~~~

The implementation of `report` is straightforward.
We create a `Future` for each result and combine them using a for-comprehension.
Note that creation and combination have to be sepate steps
if we want the API calls to happen simultaneously:

~~~ scala
def report(location: String) =
  Action.async { request =>
    val weather  = fetchWeather(location)
    val forecast = fetchForecast(location)
    for {
      w <- weather
      f <- forecast
    } yield Ok(views.html.report(location, w, f))
  }
~~~
</div>
