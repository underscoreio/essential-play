# Working with JSON {#chapter-json}

JSON is probably the most popular data format used in modern web services. Play ships with a built-in library for reading, writing, and manipulating JSON data, unsurpisingly called `play-json`. In this chapter we will discuss the techniques and best practices for handling JSON in your web applications.

<div class="callout callout-warning">
*Using `play-json` without Play*

It's easy to use `play-json` in non-Play Scala applications.
You can specify it as a dependency
by adding the following to your `build.sbt`:

~~~ scala
libraryDependencies += "com.typesafe.play" %% "play-json" % PLAY_VERSION
~~~

where `PLAY_VERSION` is the full Play version number
as a string, for example "2.3.4".
</div>
