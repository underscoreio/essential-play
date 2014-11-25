## Handling Failure

In earlier sections we saw how `Futures` are implemented on top of thread pools. Each `Future` executes on a separate thread, and there is little continuity between `Futures` in terms of stack information.

The lack of a stack is a problem for error handling. The traditional way of signalling an error in a Java application is to throw an exception, but here there is no stack for the exception to fly up. Thread-local variables are similarly of little use.

So how do we handle failure using `Futures`? This will be the focus of this section.

### Failed Futures

The first question we should ask is what happens when we throw an exception inside a `Future`:

~~~ scala
def ultimateQuestion = Future[Int] {
  // seven and a half million years...
  throw new Exception("6 * 9 != 42")
}

def index = Action.async { request =>
  for {
    answer <- ultimateQuestion
  } yield Ok(Json.obj(
    "theAnswer" -> answer
  ))
}
~~~

The surprising result is that we get a 500 error page as usual, even though the exception was most likely thrown in a separate thread from the action. How is this possible?

The answer lies in something called *failed futures*. A `Future` can actually be in one of three states: *incomplete*, *complete*, or *failed*:

 - *incomplete* futures still have work to do---they have not started or have not run to completion;
 - *complete* futures have finished executing after successfully calculating a result;
 - *failed* futures have finished executing after being terminated by an exception.

When a `Future` fails, the exception thrown is cached and passed on to subsequent futures. If we attempt to tranform the `Future` we simply get another failure:

 - `map` and `flatMap` fail immediately passing the exception along;
 - `Future.sequence` passes along the first failure it finds.

In our example, the failure in `ultimateQuestion` is passed on as the result of `index`. Play intercepts the failure and creates a 500 error page just as it would for a thrown exception in a synchronous action.

### Transforming Failures

It sometimes makes sense to intercept failed futures and turn them into successes. `Future` contains several methods to do this.

#### *recover*

The `recover` method of [`scala.concurrent.Future`] has similar semantics to a `catch` block in regular Scala. We provide a partial function that catches and transforms into successful results:

~~~ scala
val future1: Future[Int] = Future[Int] {
  throw new NumberFormatException("not 42!")
}

val future2: Future[Int] = future1.recover {
  case exn: NumberFormatException =>
    43
}
~~~

If `future1` completes without an exception, `future2` completes with the same value. If `future1` fails with a `NumberFormatException`, `future2` completes with the value `43`. If `future1` fails with any other type of exception, `future2` fails as well.

#### *recoverWith*

`recoverWith` is similar to `recover` except that our handler block has to return a `Future` of a result. It is the `flatMap` to `recover's` `map`:

~~~ scala
val future2: Future[Int] = future1.recoverWith {
  case exn: NumberFormatException =>
    Future(43)
}
~~~

#### *transform*

If `recover` is similar to `map` and `recoverWith` is similar to `flatMap`, `transform` is similar to `fold`. We supply two functions as parameters, one to handle successes and one to handle failures:

~~~ scala
val future2: Future[String] = future1.transform(
  s = (result: Int)    => (result * 10).toString,
  f = (exn: Throwable) => "43"
)
~~~

### Creating Failures

We occasionally want to create a future containing a new exception. It is undignified for a functional programmers to write `throw` in our code, so we tend to use the `Future.failed` method instead:

~~~ scala
val future3 = Future.failed[Int](new Exception("Oh noes!"))
~~~

Stack information is preserved correctly in the `Future` as we might expect.

### Failures in For-Comprehensions

Failure propagation in `Futures` has similar semantics to the propagation of `None` in `Options`. Once a failure occurs, it is propagated by calls to `map` and `flatMap`, shortcutting any mapping functions we provide. This gives `for` comprehensions over `Futures` familiar error-handling semantics:

~~~ scala
val result = for {
  a <- Future.failed[Int](new Exception("Badness!"))
  b <- Future(a + 1) // this expression is not executed
  c <- Future(b + 1) // this expression is not executed
} yield c + 1        // this expression is not executed
~~~

### Take Home Points

When we use `Futures`, our code is distributed across a thread pool. There is no common stack so exceptions cannot be propagated up through function calls in a conventional manner.

To work around this, Scala `Futures` catch any exceptions we throw and propagate them through calls to `map` and `flatMap` as *failed `Futures`*.

If we return a failed `Future` from an asynchronous action, Play responds as we might expect. It intercepts the exception and passes it to the `Global.onError` handler, creating an error 500 page.

We can use failed `Futures` deliberately as a means of propagating errors through our code. We can create failed `Futures` with `Future.failed` and transform failures into successes using `recover`, `recoverWith`, or `transform`.

**We should use failed futures only in rare circumstances.** Unlike `Either` and `Option`, `Future` doesn't require developers to handle errors, so heavy reliance on failed futures can lead to uncaught errors. As Scala developers we should always prefer using types as a defence mechanism rather than hiding them away to be ignored.
