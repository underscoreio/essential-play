## Thread Pools and *ExecutionContexts*

In the previous section we saw how to sequence and compose asyncronous code using [`scala.concurrent.Future`]. We didn't discuss how `Futures` are allocated behind the scenes. There is a lot of hidden library code at work creating threads, scheduling futures, and passing values from one future to another.

In this section we will take a brief look at how `Futures` are scheduled in Scala and Play. We will be introduced to the concept of a *thread pool*, and we'll see how to allocate futures to specific pools. We will also learn what an `ExecutionContext` is and why we need one.

### *ExecutionContexts*

In the previous section we ignored a crucial implementation detail---whenever we create a `Future` we have to tell Play *how to schedule it*. We do this by passing an implicit parameter of type [`scala.concurrent.ExecutionContext`] to the constructor:

~~~ scala
val ec: ExecutionContext = // ...

val future: Future[Int] = Future {
  // complex computation...
  1 + 1
}(ec)
~~~

The `ExecutionContext` parameter is actually marked `implicit` so we can typically ignore it in our code:

~~~ scala
implicit val ec: ExecutionContext = // ...

val future: Future[Int] = Future {
  // complex computation...
  1 + 1
}
~~~

So far we have been introduced to four methods that create `Futures`. In each case we have ignored an implicit `ExecutionContext` parameter to focus the discussion on composition. Here are the extra parameters for clarity:

~~~ scala
package scala.concurrent

object Future {
  def apply[A](expr: => A)
      (implicit ec: ExecutionContext): Future[A] = // ...

  def sequence[A](futures: Seq[Future[A]])
      (implicit ec: ExecutionContext): Future[Seq[A]] = // ...
}

trait Future[A] {
  def map[B](func: A => B)
      (implicit ec: ExecutionContext): Future[B] = // ...

  def flatMap[B](func: A => B)
      (implicit ec: ExecutionContext): Future[B] = // ...
}
~~~

Why are `ExecutionContexts` important? Whenever we create a `Future`, *something* needs to allocate it to a thread and execute it, and there are many different strategies that can be used. The `ExecutionContext` encapsulates all of the resources and configuration necessary for this and allows us to ignore it when writing application code.

<div class="callout callout-info">
*Threads and Thread Pools*

As an aside, let's take a brief look at how Scala and Play schedule `Futures`.

The simplest naïve approach we can take is to create a new thread for every `Future`. This is problematic for two reasons:

 1. There is an overhead to starting up and shutting down threads that becomes significant when dealing with large numbers of small asynchronous tasks.

 2. At high levels of concurrency we may have many threads in operation at once. The cost of *context-switching* quickly becomes significant, causing our application to *thrash* and lose performance.

Modern asynchronous programming libraries use *thread pools* to avoid these problems. Rather than create new threads on demand, they pre-allocate a fixed pool of threads and keep them running all the time. Whenever we create a new `Future` it gets passed to the thread pool for eventual execution. The pool operates in a continuous loop:

 1. wait for a thread to become available;
 2. wait for a future to need executing;
 3. execute the future;
 4. repeat from step 1.

There are many parameters to thread pools that we can tweak: the number of threads in the pool, the capacity to allocate extra threads at high load, the algorithm used to select free threads, and so on. Fortunately, in many cases we can simply use sensible defaults provided by libraries like Play.
</div>

### Play's *ExecutionContext*

Play operates several thread pools internally and provides one---the *default application thread pool*---for use in our applications. To use the thread pool, we simply have to import its `ExecutionContext` wherever we create `Futures`:

~~~ scala
import play.api.libs.concurrent.Execution.defaultContext

def index = Future {
  // and so on...
}
~~~

The default application thread pool is sufficient for most cases, but advanced users can tweak its parameters and allocate extra thread pools if required. See Play's [documentation on thread pools][docs-thread-pools] for more information.

<div class="callout callout-danger">
*Scala's Default ExecutionContext*

The Scala standard library also provides a default `ExecutionContext`. This is suitable for use in regular Scala applications, but we **should not use it in Play web applications.**

~~~ scala
// DON'T USE THIS:
import scala.concurrent.ExecutionContext.Implicits.global

// USE THIS INSTEAD:
import play.api.libs.concurrent.Execution.defaultContext
~~~
</div>

### Take Home Points

Whenever we create a `Future`, we need to allocate it to a thread pool by providing an implicit `ExecutionContext`.

Play provides a default thread pool and `ExecutionContext` on which we can schedule work. Simply importing this context is enough to use `Futures` in our code:

~~~ scala
import play.api.libs.concurrent.Execution.defaultContext

val f = Future {
  // and so on ...
}
~~~

Scala also provides a default `ExecutionContext`. **We should not use this `ExecutionContext` in out `Play` applications.**
