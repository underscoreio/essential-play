---
layout: page
title: Handling Failure
---

# Handling Failure

TODO:

 - Futures don't have a stack -- what happens to exceptions?
 - How does this affect Globals.scala?

## Failed Futures

TODO:

 - Futures catch exceptions
 - Become failed futures
 - Exceptions still useful even if not thrown (contain stack traces)
 - Shortcut semantics in `map`/`flatMap` a bit like `Option`

## Play's Response to Failed Futures

TODO:

 - Async actions call the global error handler if they return a failed future
 - Show Global.scala example

## Take Home Points

TODO:

 - No stack in futures
 - Exceptions still useful even if not thrown (contain stack traces)
 - Globals.scala is applicable to async actions too
 - Error handler called when an action throws an exception
