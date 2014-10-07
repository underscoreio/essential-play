---
layout: page
title: Async and Concurrency
---

# Async and Concurrency

There are many long-running operations that may require a web application to wait around for an answer. Examples include complex computations, database access, or remote network access. This is important because modern web applications tend to be implemented as collections of *services* that provide different parts of a system and communicate over HTTP.

In a traditional programming model, it would be typical to *block* the thread of execution while waiting for these long-running tasks such as network access to complete. This is inefficient as it ties up resources (threads or processes) for the duration of the task.

In modern web application archtecture we prefer a [non-blocking] programming model where we relinquish local resources and reclaim them when the long-running task completes. This lowers resource contention and allows the web application to respond to higher volumes of incoming requests with more predictable latency.

In this section we will see how to implement non-blocking concurrency in Scala and Play, identify some gotchas, and use the theory to build an example web application using a distributed *service-oriented architecture*.

[non-blocking]: http://en.wikipedia.org/wiki/Non-blocking_algorithm
