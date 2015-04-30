## Futures

The underpinning of our concurrent programming model
is the [`scala.concurrent.Future`] trait.
A `Future[A]` represents an asynchronous computation
that *will calculate a value of type `A` at some point in the future*.

`Futures` are a general tool from the Scala core library,
but they are used heavily in Play.
We will start by looking at the general case,
and tie them into Play later on in this chapter.

### The Ultimate Answer

Let's define a long-running computation:

~~~ scala
def ultimateAnswer: Int = {
  // seven and a half million years later...
  42
}
~~~

Calling `ultimateAnswer` executes the long-running computation on the current thread.
As an alternative, we can use a `Future` to run the computation asynchronously,
and continue to run the current thread in parallel:

~~~ scala
val f: Future[Int] = Future {
  // this code is run asynchronously:
  ultimateAnswer
}

println("Continuing to run in parallel...")
~~~

At some point in the future `ultimateAnswer` will complete.
The result is cached in `f` for eventual re-use.
We can schedule callbacks to run when `f` completes.
The callbacks accept the cached value as input:

~~~ scala
f.onSuccess {
  case number =>
    println("The answer is " + number + ". Now, what was the question?")
}
~~~

It doesn't matter how many callbacks we register
or whether we register them before or after `ultimateAnswer` completes.
`scala.concurrent` ensures that the `f` is executed exactly once,
and each of our callbacks is executed once after `f` completes.

The final output of our program looks like this:

~~~
Continuing to run in parallel...
The answer is 42. Now, what was the question?
~~~

### Composing Futures

Callbacks are the simplest way to introduce `Futures` in a book,
but they aren't useful for production code because they don't return values.
This causes at least two problems:

 - we have to rely on mutable variables to pass around state;
 - code cab be difficult to read because we have to write it in a different order than it is executed.

Fortunately, there are other ways of sequencing `Futures`.
We can *compose* them in a functional fashion, wiring them together
so that the result of one `Future` is used as an input for another.
This approach allows us to avoid mutable state and write expressions
in the order we expect them to run.
We hand off the details of scheduling execution to library code in `scala.concurrent`.

Let's see some of the important methods for composing futures:

#### *map*

The `map` method allows us to sequence a future with a block of synchronous code.
The synchronous code is represented by a simple function:

~~~ scala
trait Future[A] {
  def map[B](func: A => B): Future[B] = // ...
}
~~~

The result of calling `map` is a new future that
*sequences* the computation in the original future with `func`.
In the example below, `f2` is a future that waits for `f1` to complete,
then transforms the result using `conversion`.
Both operations are run in the background one after the other
without affecting other concurrently running tasks:

~~~ scala
def conversion(value: Int): String =
  value.toString

val f1: Future[Int]    = Future(ultimateAnswer)
val f2: Future[String] = f1.map(conversion)
~~~

We can call `map` on the same `Future` as many times as we want.
The order and the timing of the calls is insignificant---the
value of `f1` will be delivered to `f2` and `f3` once only when `f1` completes:

~~~ scala
val f1: Future[Int]    = Future { ultimateAnswer }
val f2: Future[Int]    = f1 map { _ + 1 }
val f3: Future[Double] = f1 map { _.toDouble }
~~~

We can also build large sequences of computations by chaining calls to `map`:

~~~ scala
val f4L Future[String] = f1 map { _ + 1 } map (conversion) map { _ + "!" }
~~~

The final results of `f1`, `f2`, `f3`, and `f4` above are `42`, `43`, `"42"`, and `"43!"` respectively.

#### *flatMap*

The `flatMap` method allows us to sequence a future with a block of asynchronous code.
The asynchronous code is represented by a function that returns a future:

~~~ scala
trait Future[A] {
  def flatMap[B](func: A => Future[B]): Future[B] = // ...
}
~~~

The result of calling `flatMap` is a new future that:

 - waits for the first `Future` to complete;
 - passes the result to `func` obtaining a second `Future`;
 - waits for the second `Future` to complete;
 - yields the result of the second `Future`.

This has a similar sequencing-and-flattening effect to the `flatMap` method on [`scala.Option`]

~~~ scala
def longRunningConversion(value: Int): Future[String] =
  Future {
    // some length of time...
    value.toString
  }

val f1: Future[Int]    = Future(ultimateAnswer)
val f2: Future[String] = f1.flatMap(value => Future(value + 1))
val f3: Future[String] = f1.flatMap(longRunningConversion)
~~~

The final results of `f1` and `f2` and `f3` above are `42`, `43` and `"42"` respectively.

#### Wait... Future is a Monad?

Yes---we're glad you noticed!

Functional programming enthusiasts will note that the presence of
a `flatMap` method means `Future` is a *monad*.
This means we can use it with regular Scala for-comprehensions.

As an example, suppose we are creating a web service to monitor traffic on a set of servers.
Assume we have a method `getTraffic` to interrogate one of our servers:

~~~ scala
def getTraffic(hostname: String): Future[Double] = {
  // ...non-blocking HTTP code...
}
~~~

We want to combine the traffic from three separate servers to produce a single aggregated value.
Here are two ways of writing the code using for-comprehensions:

*Single expression*

~~~ scala
val total: Future[Double] = for {
  t1 <- getTraffic("server1")
  t2 <- getTraffic("server2")
  t3 <- getTraffic("server3")
} yield t1 + t2 + t3
~~~

*Create-then-compose*

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

These examples are easy to read---each one demonstrates the elegance
of using `for` syntax to sequence asynchronous code.
However, we should note an an important semantic difference between the two.
One of the examples will complete much faster than the other.
Can you work out which one?

To answer this question we must look at the expanded forms of each example:

*Single expression*

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

*Create-then-compose*

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

In the *single expression* example, the calls to `getTraffic` are nested inside one another.
The code *sequences* the calls, waiting until one completes before initiating the next.

The *create-then-compose* example, by contrast,
initiates each of the calls immediately and then sequences the combination of their results.

Both examples are resource-efficient and non-blocking
but they sequence operations differently.
*Create-then-compose* calls out to the three servers in parallel
and will typically complete in roughly one third the time.
This is something to watch out for when combining futures using for-comprehensions.

<div class="callout callout-info">
*Sequencing Futures using For-Comprehensions*

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

### *Future.sequence*

`for` comprehensions are a great way to combine the results of several futures,
but they aren't suitable for combining the results of *arbitrarily sized* sets of futures.
For this we need the `sequence` method
of [`Future's` companion object][`scala.concurrent.Future$`].
Here's a simplified type signature:

~~~ scala
package scala.concurrent

object Future {
  def sequence[A](futures: Seq[Future[A]]): Future[Seq[A]] =
    // ...
}
~~~

We can use this method to convert any sequence of futures
into a future containing a sequence of the results.
This lets us generalise our traffic monitoring example to any number of hosts:

~~~ scala
def totalTraffic(hostnames: Seq[String]): Future[Double] = {
  val trafficFutures: Seq[Future[Double]] =
    hostnames.map(getTraffic)

  val futureTraffics: Future[Seq[Double]] =
    Future.sequence(trafficFutures)

  futureTraffics.map { (traffics: Seq[Double]) =>
    traffics.sum
  }
}
~~~

Note: `Future.sequence` actually accepts a `TraversableOnce` and
returns a `Future` of the same type of sequence.
Subtypes of `TraversableOnce` include sequences, sets, lazy streams,
and many of other types of collection not covered here.
This generality makes `Future.sequence` a useful and versatile method.

### Take Home Points

We use `Futures` to represent asynchronous computations.
We *compose* them using *for-comprehensions* and
methods like `map`, `flatMap`, and `Future.sequence`.

In the next section we will see how `Futures` are scheduled
behind the scenes using *thread pools* and `ExecutionContexts`.

### Exercise: The Value of (Con)Currency

The `chapter5-currency` directory in the exercises contains
a dummy application for calculating currency conversions.
The actual calculations are performed by the `toUSD` and `fromUSD`
methods in the `ExchangeRateHelpers` trait, each of which is asynchronous.

Complete the `convertOne` and `convertAll` actions in `CurrencyController`.
Use `toUSD` and `fromUSD` to perform the required conversions,
combinators on `Future` to combine the results,
and the `formatConversion` helper to provide a plain text response.
Here's an example of the expected output:

~~~ bash
bash$ curl 'http://localhost:9000/convert/100/gbp/to/usd'
100 GBP = 150 USD

bash$ curl 'http://localhost:9000/convert/100/eur/to/gbp'
100 EUR = 73.33 GBP

bash$ curl 'http://localhost:9000/convert/250/usd/to/all'
250 USD = 250 USD
250 USD = 166.67 GBP
250 USD = 227.27 EUR
~~~

Start with the simpler of the two actions, `convertOne`.
You are given source and target currencies and the amount of currency to exchange.
However, you will have to perform the conversion in three steps:

1. convert the source currency to USD;
2. convert the USD amount to the target currency;
3. format the result as a `Result[String]`.

<div class="solution">
The first step is the currency conversion itself.
The `toUSD` and `fromUSD` methods return `Futures`,
so the natural combinator is `flatMap`:

~~~ scala
val toAmount: Future[Double] =
  toUSD(fromAmount, fromCurrency).
  flatMap(usdAmount => fromUSD(usdAmount, toCurrency))
~~~

We have to format this `Future` using `formatConversion`.
This isn't an async method, so the natural combinator is `map`:

~~~ scala
val output: Future[String] =
  toAmount.map { toAmount =>
    formatConversion(
      fromAmount,
      fromCurrency,
      toAmount,
      toCurrency
    )
  }
~~~

This sequence of `flatMap` followed by `map` can be naturally
expressed as a `for` comprehension,
which is a great way of writing the final result:

~~~ scala
def convertOne(
    fromAmount: Double,
    fromCurrency: Currency,
    toCurrency: Currency) =
  Action.async { request =>
    for {
      usdAmount <- toUSD(fromAmount, fromCurrency)
      toAmount  <- fromUSD(usdAmount, toCurrency)
    } yield Ok(formatConversion(
      fromAmount,
      fromCurrency,
      toAmount,
      toCurrency
    ))
  }
~~~
</div>

With `convertOne` out of the way, tackle `convertAll`.
You are given a source currency amount and asked to convert it
to *all* other currencies in `ExchangeRateHelpers.currencies`.
This involves transformations on `Future` and `Seq`.

<div class="solution">
Interleaving transformations on monads is messy.
It makes sense to do all the transformations we can
in one monad before switching to the other.
In this exercise, this means transforming all the way
from source `Currency` to `String` output before
working out how to combine the results.
Start by iterating over `currencies`,
calculating the line of output needed for each:

~~~ scala
val outputLines: Seq[Future[String]] =
  currencies.map { toCurrency: Double =>
    for {
      usdAmount <- toUSD(fromAmount, fromCurrency)
      toAmount  <- fromUSD(usdAmount, toCurrency)
    } yield formatConversion(
      fromAmount,
      fromCurrency,
      toAmount,
      toCurrency
    )
  }
~~~

Now combine these `Strings` to a single `Result`.
We can convert the `Seq[Future[String]]` to a `Future[Seq[String]]`
using `Future.sequence`, after which we just use `map`:

~~~ scala
val result: Future[Result] =
  Future.sequence(outputLines).
    map(lines => Ok(lines mkString "\n"))
~~~

The final code looks like this:

~~~ scala
def convertAll(
    fromAmount: Double,
    fromCurrency: Currency) =
  Action.async { request =>
    val outputLines: Seq[Future[String]] =
      currencies.map { toCurrency: Double =>
        for {
          usdAmount <- toUSD(fromAmount, fromCurrency)
          toAmount  <- fromUSD(usdAmount, toCurrency)
        } yield formatConversion(
          fromAmount,
          fromCurrency,
          toAmount,
          toCurrency
        )
      }

    Future.
      sequence(outputLines).
      map(lines => Ok(lines mkString "\n"))
  }
~~~

There's a lot of redundant code between `convertOne` and `convertAll`.
In the model solution we've factored this out into its own helper method.
</div>
