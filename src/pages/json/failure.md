---
layout: page
title: Handling Failure
---

# Handling Failure

We have seen everything we need to read and write arbitrary JSON data. We are almost ready to create full-featured JSON REST APIs. There's only one more thing we need to cover: failure.

When a JSON REST endpoint fails, it needs to return JSON to the client. We can do this manually in the case of expected errors, but what about unexpected errors such as exceptions?

In this section we will look at replacing Play's default 400 and 500 error pages with our own JSON error pages.

TODO:

 - Play generates 404 and 500 pages for us
 - We don't want HTML responses in a JSON web service
 - We can override the default behaviour in Globals.scala
 - Let's see some examples

## Routing Errors

TODO:

 - Show Global.scala example

## Exceptions

TODO:

 - Show Global.scala example

## Take Home Points

TODO:

 - Globals.scala lets us customise error handlers
 - Error handler called when an action throws an exception

