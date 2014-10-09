---
layout: page
title: Asynchronous Actions
---

## Asynchronous Actions

In the previous section we saw how to create and compose `Futures` to schedule asyncronous tasks. In this section we will see how  to create *asynchronous actions* that use `Futures` to process web requests.

## Synchronous versus Asynchronous Actions

Whenever our web application processes a request, Play allocates a thread from our application's thread pool to run the corresponding action.

All of the actions we have written so far have been *synchronous* -- they must be executed completely from beginning to end before Play can recycle the active thread.

At high load the thread pool can become exhausted. If this happens, pending requests must be scheduled for when a thread becomes free. As long as actions are short-running this provides graceful degredation under load. However, long-running actions can cause scheduling problems and latency spikes:

~~~ scala
def difficultToSchedule = Action { request =>
  // this could take a while...
  Ok(longRunningComputation)
}
~~~

We should be on the lookout for long-running actions and adjust our application flow accordingly. One way of doing this is splitting our work up into easily schedulable chunks using *asynchronous actions*.

## Action.async

We write asynchronous actions using the `Action.async` method:

~~~ scala
def index = Action.async { request =>
  Future(Ok("Hello world!"))
}
~~~

`Action.async` differs from `Action.apply` in that it expects us to return a `Future[Result]` rather than a `Result`. The action sets up a chain of asynchronous computations and returns quickly. Each computation is scheduled on the thread pool separately, splitting the work up into (hopefully) managable chunks:

~~~ scala
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

## Blocking I/O

The most common causes for long-running actions are blocking I/O operations:

 - complex/unoptimised database queries;
 - large amounts of file access;
 - requests to remote web services.

We should be aware that we cannot eliminate blocking by converting a synchronous action to an asynchronous one -- we are simply shifting the work to a different thread. However, by splitting a synchronous chain of blocking operations up into a chain of asynchronous tasks, we may make the work easier to schedule at high load.

## Take Home Points

**Asyncronous actions** allow us to split up request handlers using `Futures`.

We write asynchronous actions using `Action.async`. This is similar to `Action.apply` except that we must return a `Future[Result]` instead of a plain `Result`.

If we are using blocking I/O, wrapping it in a `Future` doesn't make it go away. However, dealing with long-running tasks in shorter chunks can make actions easier to schedule under high load.


