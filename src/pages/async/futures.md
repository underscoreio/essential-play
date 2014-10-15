---
layout: page
title: Futures
---

# Futures

The underpinning of our concurrent programming model is the [scala.concurrent.Future] trait. A `Future[A]` represents an asynchronous computation that *will calculate a value of type `A` at some point in the future*.

We'll start by looking at `Futures` in isolation from Play -- let's see a simple example:

[scala.concurrent.Future]: http://www.scala-lang.org/api/2.11.2/#scala.concurrent.Future

~~~ scala
def longRunningComputation: Int = {
  // seven and a half million years later...
  42
}

val f: Future[Int] = Future {
  // this code is run asynchronously:
  longRunningComputation
}

f onSuccess {
  case number =>
    println("The answer is " + number + ". Now, what was the question?")
}

println("This might take a while...")
~~~

In this example we have a method, `longRunningComputation`, that takes a few seconds to complete.

We create a `Future` to call our method asynchronously -- our `longRunningComputation` is started in the background. The main program continues immediately, assigning the future to the variable `f` and setting up an `onSuccess` callback to print the result.

The main body of the program finishes, executing the final `println` statement. A few seconds later the `longRunningComputation` *completes*, triggering the `onSuccess` callback and printing the result. The final output looks like this:

~~~
This might take a while...
The answer is 42. Now, what was the question?
~~~

When the computation in a future has completed, the resulting value is cached in the future for eventual re-use. We can attach as many callbacks as we like, before or after its completion, and be sure the same result value will be delivered to each.

## Composing Futures

The example above uses a *callback* to react to the completion of the future. This is worrying for functional programming purists because it is an *imperative* programming style. Callbacks *aren't functional* -- they don't return a value for use elsewhere in our code. Moreover, callback-driven programming is difficult to read because the order of lines in our code doesn't match the order of execution.

Fortunately, there is more to `Future` than we have seen. `Futures` can be *composed*, allowing us to wire them together in a functional way. A vendor-supplied *execution context* works behind the scenes to sequence all of the background computations and make sure they deliver results to one another as we ask. We can write expressions in the order we expect them to run, and hand off the details of the execution to a library.

We'll learn more about execution contexts later on. For now let's see some of the important methods for composing futures:

### Map

A `Future[A]` has a *map* method that accepts an argument of type `A => B` and returns a `Future B`:

~~~ scala
trait Future[A] {
  def map[B](func: A => B): Future[B] = // ...
}
~~~

The result is a second future that *sequences* the computation in first future with the running of the function parameter:

~~~ scala
def complexConversion(value: Int): String = {
  value.toString
}

val f1: Future[Int]    = Future(longRunningComputation)
val f2: Future[String] = f1.map(complexConversion)
~~~

In this example, `f2` is a future that waits for `f1` to complete, then transforms the result using `complexConversion`. Both operations are run in the background one after the other without affecting other concurrently running tasks.

We can call `map` as many times as we want. The order and the timing of the calls to `map` is insignificant -- the same value will be delivered to each mapping function at the appropriate time:

~~~ scala
val f1: Future[Int]    = Future { longRunningComputation }
val f2: Future[Int]    = f1 map { _ + 1 }
val f3: Future[Double] = f1 map { _.toDouble }
~~~

In this example, the final results of `f1`, `f2` and `f3` will the `42`, `43` and `"42"` respectively.

### FlatMap

A `Future[A]` has a *flatMap* method that accepts an argument of type `A => Future[B]` and returns a `Future[B]`:

~~~ scala
trait Future[A] {
  def flatMap[B](func: A => Future[B]): Future[B] = // ...
}
~~~

The result is a future that:

 - waits for the first future to complete;
 - passes the result to `func`;
 - waits for the result of `func` to complete;
 - yields the result of the result.

This has a similar sequencing-and-flattening effect to the `flatMap` method on [scala.Option]:

~~~ scala
def longRunningConversion(value: Int): Future[String] = {
  // some length of time...
  value.toString
}

val f1: Future[Int]    = Future(longRunningComputation)
val f2: Future[String] = f1.flatMap(longRunningConversion)
~~~

Functional programming enthusiasts will note that the presence of a `flatMap` method means `Future` is a *monad*.

[scala.Option]: http://www.scala-lang.org/api/2.11.2/#scala.Option

### Wait... Future is a Monad? We Can Use For-Comprehensions!

Because `Future` has `map` and `flatMap` methods, we can use it with regular Scala for-comprehensions.

{% comment %}
Here are our previous two examples re-written using this syntax:

<div class="row">
<div class="col-sm-6">
**The `map` example**

~~~ scala
for {
  value <- Future(longRunningComputation)
} yield complexConversion(value)
~~~
</div>

<div class="col-sm-6">
**The `flatMap` example**

~~~ scala
for {
  value1 <- Future(longRunningComputation)
  value2 <- longRunningConversion(value1)
} yield value2
~~~
</div>
</div>
{% endcomment %}

As an example, suppose we have three web services and a fourth service that monitors their total traffic. Assume we have a method `getTraffic` to interrogate a single remote host:

~~~ scala
def getTraffic(hostname: String): Future[Double] = {
  // ...non-blocking HTTP code...
}
~~~

We want to combine the results of three separate calls to `getTraffic`. Here are two ways of writing the code using for-comprehensions:

<div class="row">
<div class="col-sm-6">
**Single expression**

~~~ scala
val total: Future[Double] = for {
  t1 <- getTraffic("server1")
  t2 <- getTraffic("server2")
  t3 <- getTraffic("server3")
} yield t1 + t2 + t3
~~~
</div>

<div class="col-sm-6">
**Create-then-compose**

~~~ scala
val traffic1 = getTraffic("server1")
val traffic2 = getTraffic("server2")
val traffic3 = getTraffic("server3")

val total: Future[Double] = for {
  t1 <- traffic1
  t2 <- traffic2
  t3 <- traffic3
} yield t1 + t2 + t3
~~~
</div>
</div>

Both of these snippets are easy to read. However, their semantics are quite different and they take different amounts of time to complete.

What is the difference and which snippet will be faster? To answer this we must look at their expanded forms:

<div class="row">
<div class="col-sm-6">
**Single expression**

~~~ scala
val total: Future[Double] =
  getTraffic("server1") flatMap { t1 =>
    getTraffic("server2") flatMap { t2 =>
      getTraffic("server3") map { t3 =>
        t1 + t2 + t3
      }
    }
  }
~~~
</div>

<div class="col-sm-6">
**Create-then-compose**

~~~ scala
val traffic1 = getTraffic("server1")
val traffic2 = getTraffic("server2")
val traffic3 = getTraffic("server3")

val total: Future[Double] =
  traffic1 flatMap { t1 =>
    traffic2 flatMap { t2 =>
      traffic3 map { t3 =>
        t1 + t2 + t3
      }
    }
  }
~~~
</div>
</div>

In the *single expression* example, the calls to `getTraffic` are nested inside one another -- the code *sequences* the calls, waiting until one completes before initiating the next.

The *create-then-compose* example, by contrast, initiates each of the calls immediately and then sequences the combination of their results.

Both examples are resource-efficient and non-blocking, but *create-then-compose* will typically complete in about one third the time. This is something to watch out for when combining futures using for-comprehensions.

<div class="callout callout-info">
#### Sequencing Futures using For-Comprehensions

 1. Work out which calculations are dependent on the results of which others:

    ~~~
    poll server 1    \
    poll server 2    -+->    total the results
    poll server 3    /
    ~~~

 2. Declare futures for each independent steps (no incoming arrows) in your graph:

    ~~~ scala
    val traffic1 = getTraffic("server1")
    val traffic2 = getTraffic("server2")
    val traffic3 = getTraffic("server3")
    ~~~

 3. Use for-comprehensions to combine the immediate results:

    ~~~ scala
    val total: Future[Double] = for {
      t1 <- traffic1
      t2 <- traffic2
      t3 <- traffic3
    } yield t1 + t2 + t3
    ~~~

  4. Repeat for the next step in the sequence (if any).
</div>

### Future.sequence

For comprehensions are a great way to combine the results of several futures, but they aren't suitable for combining the results of *arbitrarily sized* sets of futures. For this we need the `sequence` method of [Future's companion object]. Here's a simplified type signature:

[Future's companion object]: http://www.scala-lang.org/api/2.11.2/#scala.concurrent.Future$

~~~ scala
package scala.concurrent

object Future {
  def sequence[A](futures: Seq[Future[A]]): Future[Seq[A]] = // ...
}
~~~

We can use this method to convert any sequence[^sequence] of futures into a future of a sequence of the results. We can use this method to generalise our traffic monitoring example to any number of hosts:

~~~ scala
def totalTraffic(hostnames: Seq[String]): Future[Double] = {
  val trafficFutures: Seq[Future[Double]] = hostnames.map(getTraffic)

  val futureTraffics: Future[Seq[Double]] = Future.sequence(trafficFutures)

  futureTraffics.map(_.sum)
}
~~~

[^sequence]: It actually accepts a `TraversableOnce` of futures, which includes sequences, sets, lazy streams, and many of other types of collection not covered here.

### Take Home Points

We use `Futures` to represent asynchronous computations.

We *combine* futures using methods like `map` and `flatMap` and `sequence`.

In the next section we will see how `Futures` are scheduled.
