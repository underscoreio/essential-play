---
layout: page
title: Thread Pools
---

## Thread Pools

In the previous section we saw how `Futures` allow us to sequence and compose asyncronous tasks.

In this section we will learn Scala and Play schedule `Futures` using *thread pools*, and will see how to allocate futures to specific pools.

## *ExecutionContexts*

`Futures` abstract away the problem of implementing asynchronous code using tools like threads, semaphores, and locks. Whenever we create a `Future`, Scala or Play makes intelligent decisions about where, when, and how to run it.

Every time we create a new `Future`, we need to tell Scala or Play what execution strategy to use. We do this by passing an implicit parameter of type [scala.concurrent.ExecutionContext].

In the previous section we saw four methods that created new `Futures`. We ignored the `ExecutionContext` arguments to focus the discussion on composition. Here they are for clarity:

~~~ scala
package scala.concurrent

object Future {
  def apply[A](expr: => A)
      (implicit context: ExecutionContext): Future[A] = // ...

  def sequence[A](futures: Seq[Future[A]])
      (implicit context: ExecutionContext): Future[Seq[A]] = // ...
}

trait Future[A] {
  def map[B](func: A => B)
      (implicit context: ExecutionContext): Future[B] = // ...

  def flatMap[B](func: A => B)
      (implicit context: ExecutionContext): Future[B] = // ...
}
~~~

## Which *ExecutionContext* to use?

Play provides a default `ExecutionContext` for us to schedule `Futures` in our web applications. Simply importing the context is enough for it to be available as an implicit parameter:

~~~ scala
import play.api.libs.concurrent.Execution.defaultContext

def index = Future {
  // and so on...
}
~~~

Play expects us to schedule `Futures` using its *default application execution context* [play.api.libs.concurrent.Execution.defaultContext]. We should import this whenever we use `Futures` in our applications.

<div class="callout callout-danger">
#### Warning: Scala's Default ExecutionContext

The Scala standard library also provides a default `ExecutionContext`. This is suitable for use in regular Scala applications, but we **should not use it in Play web applications.** Use play

~~~ scala
// DON'T USE THIS!
import scala.concurrent.ExecutionContext.Implicits.global

// Use play.api.libs.concurrent.Execution.defaultContext instead
~~~
</div>

## Thread Pools

Spinning up a new thread for every `Future` we create would incur lots of overhead in terms of claiming and releasing system resources, so most `ExecutionContexts` use *pools* of pre-allocated threads. The execution context itself runs in its own thread, repeatedly running the following loop:

 1. find a free thread in the pool;
 2. find an incomplete `Future` that has not been scheduled;
 3. execute the body of the `Future` on the thread and cache the result;
 4. goto step 1.

Play operates several thread pools internally, of which the *default application thread pool* is one. This is the pool we use in our application code.

In advanced situations we may decide to create our own execution contexts for some parts of our application. This is beyond the scope of this documentation. For more discussion see Play's [documentation on thread pools].

[documentation on thread pools]: https://www.playframework.com/documentation/2.3.x/ThreadPools

## Take Home Points

Whenever we create a `Future`, we need to allocate it to a thread pool by providing an implicit `ExecutionContext` parameter.

Play provides a default thread pool and `ExecutionContext` on which we can schedule work. Simply importing this context is enough to use `Futures` in our code:

~~~ scala
import play.api.libs.concurrent.Execution.defaultContext

val f = Future {
  // and so on ...
}
~~~

Scala also provides a default `ExecutionContext`. **We should not use this `ExecutionContext` in out `Play` applications.**