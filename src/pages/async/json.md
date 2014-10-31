---
layout: page
title: Working with JSON
---

# Working with JSON

TODO:

 - We have seen how to process JSON in requests
 - Now let's look at processing JSON in async code.

## JSON in Requests

TODO:

 - Lift JSON extraction into the Future monad
 - Extract JSON from request, return it as a `Future`
 - `def requestJson(request: Request[AnyContent]): Future[JsValue]`
 - Return a failed `Future` if this fails

## JSON in Successful Results

TODO:

 - Serialize data as JSON using type classes within the context of a Future
 - If we're already working in the `Future` monad, this is simply a `map` operation using `Json.toJson`

## Returning Error JSON

TODO: Serialize errors from failed futures as JSON
