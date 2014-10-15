---
layout: page
title: Handling failure
---

# Handling failure

TODO:

 - Futures don't have a stack -- what happens to exceptions?
 - How does this affect Globals.scala?

## Failed futures

TODO:

 - Futures catch exceptions
 - Become failed futures
 - Exceptions still useful even if not thrown (contain stack traces)
 - Shortcut semantics in `map`/`flatMap` a bit like `Option`

## Play's response to failed futures

TODO:

 - Async actions call the global error handler if they return a failed future
 - Show Global.scala example

## Take home points

TODO:

 - No stack in futures
 - Exceptions still useful even if not thrown (contain stack traces)
 - Globals.scala is applicable to async actions too
 - Error handler called when an action throws an exception
