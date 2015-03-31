## Asynchronous Actions

In the previous sections we saw how to create and compose `Futures` to schedule asyncronous tasks. In this section we will see how to use `Futures` to create *asynchronous actions* in Play.

### Synchronous vs Asynchronous Actions

Play is built using `Futures` from the bottom up. Whenever we process a request, our action is executed in a thread on the *default application thread pool*.

All of the actions we have written so far have been *synchronous*---they run from beginning to end in a single continuous block. The thread Play allocates to the request is tied up for the duration---only when we return a `Result` can Play recycle the thread to service another request.

At high load there can be more incoming requests than there are threads in the application thread pool. If this happens, pending requests must be scheduled for when a thread becomes free. As long as actions are short-running this provides graceful degredation under load. However, long-running actions can cause scheduling problems and latency spikes:

~~~ scala
def difficultToSchedule = Action { request =>
  // this could take a while...
  Ok(ultimateAnswer)
}
~~~

We should look out for long-running actions and adjust our application flow accordingly. One way of doing this is splitting our work up into easily schedulable chunks using *asynchronous actions*.

### *Action.async*

We write asynchronous actions using the `Action.async` method:

~~~ scala
def index = Action.async { request =>
  Future(Ok("Hello world!"))
}
~~~

`Action.async` differs from `Action.apply` only in that it expects us to return a `Future[Result]` instead of a `Result`. When the body of the action returns, Play is left to execute the resulting `Future`.

We can use methods such as `map` and `flatMap` to split long multi-stage workload into sequences of shorter `Futures`, allowing Play to schedule the work more easily across the thread pool along-side other pending requests:

~~~ scala
import scala.concurrent.ExecutionContext
import play.api.libs.concurrent.Execution.Implicits.defaultContext

def getTraffic(hostname: String)
    (implicit context: ExecutionContext): Future[Double] = {
  // ...non-blocking HTTP code...
}

def traffic = Action.async { request =>
  val traffic1 = getTraffic("server1")
  val traffic2 = getTraffic("server2")
  val traffic3 = getTraffic("server3")

  for {
    t1   <- traffic1
    t2   <- traffic2
    t3   <- traffic3
    total = t1 + t2 + t3
  } yield Ok(Json.obj("traffic" -> total))
}
~~~

### Blocking I/O

The most common causes for long-running actions are blocking I/O operations:

 - complex/unoptimised database queries;
 - large amounts of file access;
 - requests to remote web services.

We cannot eliminate blocking by converting a synchronous action to an asynchronous one---we are simply shifting the work to a different thread. However, by splitting a synchronous chain of blocking operations up into a chain of asynchronously executing `Futures`, we can make the work easier to schedule at high load.

### Take Home Points

**Asyncronous actions** allow us to split up request handlers using `Futures`.

We write asynchronous actions using `Action.async`. This is similar to `Action.apply` except that we must return a `Future[Result]` instead of a plain `Result`.

If we are using blocking I/O, wrapping it in a `Future` doesn't make it go away. However, dealing with long-running tasks in shorter chunks can make actions easier to schedule under high load.
