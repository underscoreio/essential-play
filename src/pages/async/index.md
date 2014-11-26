# Async and Concurrency {#chapter-async}

Web applications often have to wait for long-running operations such as database and network access. In a traditional *synchronous* programming model the application has to *block* to wait for these to complete. This is inefficient as it ties up threads and processes while no useful work is happening.

In modern web application archtecture we prefer to use a *[non-blocking][link-non-blocking]* programming model. Non-blocking code relinquishes local resources and reclaims them once long-running tasks complete. This lowers resource contention and allows applications to handle higher traffic loads with predictable latency.

Non-blocking code is also essential for *distributing* work across machines. Modern non-trivial web applications are implemented as collections of *services* that communicate over HTTP. This is impossible (or, at least, not scalable) in conventional blocking architectures.

In this section we will see how to implement non-blocking concurrency in Scala and Play using a functional programming tool called *Futures*.
