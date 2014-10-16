---
layout: page
title: Handling Failure
---

# Handling Failure

At this point we have covered all the basics for this chapter. We have learned how to set up routes, write `Action`s, handle `Request`s, and create `Result`s.

In this final section of the chapter we will take a first look at a theme that runs throughout the course -- failures and error handling. In future chapters we will look at how to generate good error messages for our users. In this section we will see what error messages Play provides for us.

## Compilation Errors

Play reports compilation errors in two places: on the SBT console, and via 500 error pages. If you've been following the exercises so far, you will have seen this already. When we run a development web server using `sbt run` and make a mistake in our code, Play responds with an error page:

![Internal error: Play's compilation error 500 page](compile-error.png)

While this behaviour is useful, we should be aware of two drawbacks:

 1. The web page only reports the *first* error from the SBT console. A single typo in Scala code can create several compiler errors, so we often have to look at the complete output from SBT to trace down a bug.

 2. When we use `sbt run`, Play only recompiles our code when we refresh the web page. This sometimes slows down development because we have to constantly switch back and forth between editor and browser.

    We can write and debug code faster if we use SBT's *continuous compilation* mode instead of `sbt run`. To start continuous compilation, type `~compile` on the SBT console:

    ~~~
    [hello-world] $ ~compile
    [success] Total time: 0 s, completed 11-Oct-2014 11:46:28
    1. Waiting for source changes... (press enter to interrupt)
    ~~~

    In continuous compilation mode, SBT recompiles our code every time we change a file. However, we have to go back to `sbt run` to see the changes in a browser.

## Runtime Errors

If our code compiles but fails at runtime, we get a similar error page that points to the source of the exception. The exception is reported on the SBT console as well as on the page:

![Internal error: Play's default error 500 page](internal-error.png)

## Routing Errors

Play generates a 404 page if it can't find an appropriate route for an incoming request. This error *doesn't* appear on the console:

![Not found: Play's 404 routing error page](not-found-error.png)

If Play finds a route but can't parse the parameters from the path and query string, it issues a similar-looking 400 response:

![Bad request: Play's 400 routing error page](bad-request-error.png)


## Take Home Points

Play ships with a default 500 error page out of the box. It gives us nice error messages for compile errors and exceptions during development. Similarly, Play provides default 404 and 400 pages for routing errors.

These error messages are useful during development, but we should remember to disable it before we put code into production. We will see this next chapter when we create our own HTML and learn how to handle form data.
