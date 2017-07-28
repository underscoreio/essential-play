# Essential Play

Written by [Dave Gurnell](http://twitter.com/davegurnell) and
[Noel Welsh](http://twitter.com/noelwelsh).
Copyright [Underscore Consulting LLP](http://underscore.io), 2015-2017.

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.


## Overview

[Essential Play][essential-play] is an introduction to [Play Framework][play-framework] for professional developers.
Essential Play covers the core patterns that new developers need to be productive in the framework.
It's designed to get you productive as quickly as possible, and avoid the dark and confusing corners of the framework.


## Play 2.3? Whaaat?!

The current version of Essential Play is written for Play 2.3.
At the time of writing, Play 2.5 is the current version and Play 2.6 is near release.
The book is designed to be a minimal introduction and most content is still relevant,
but it needs some additional material to bring it up-to-date:

- modifications to the JSON chapter to cover `JsDefined` and `JsUndefined`;
- an additional chapter on dependency injection;
- an additional chapter on wrangling configuration files;
- (optional) an additional chapter on using Play with Akka Streams.

I'm actively seeking contributors to help with these updates.

DM me on Github or Twitter if you're interested in helping out!

Cheers,
Dave


## Building

Essential Scala uses [Underscore's ebook build system][ebook-template].

The simplest way to build the book is to use [Docker Compose](http://docker.com):

- install Docker Compose (`brew install docker-compose` on OS X; or download from [docker.com](http://docker.com/)); and
- run `go.sh` (or `docker-compose run book bash` if `go.sh` doesn't work).

This will open a `bash` shell running inside the Docker container which contains all the dependencies to build the book. From the shell run:

- `npm install`; and then
- `sbt`.

Within `sbt` you can issue the commands `pdf`, `html`, `epub`, or `all` to build the desired version(s) of the book. Targets are placed in the `dist` directory:


[ebook-template]: https://github.com/underscoreio/underscore-ebook-template
[essential-play]: http://underscore.io/books/essential-play/
[play-framework]: http://playframework.org
