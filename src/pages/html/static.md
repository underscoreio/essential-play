## Serving Static Assets

It's a shame, but we can't yet implement web sites in 100% Scala
(although [some valiant souls][link-scalajs] are working on getting us there).
There are other resources that need to be bundled with our HTML,
including, CSS, Javascript, image assets, and fonts.
Play includes a build system called [`sbt-web`][link-sbt-web]
help compile and serve non-Scala assets.

### The *Assets* Controller

Play provides an `Assets` controller for serving static files from the filesystem.
This is ideal for images, fonts, CSS, and Javascript files.
To configure the controller, simply add the following to the end of your `routes`:

~~~
GET  /assets/*file  controllers.Assets.at(path="/public", file)
~~~

Make a directory called `public` in the root directory of your project.
The `Assets` controller serves any files in the `public` directory
under the `/assets` URL prefix. It also provides reverse routes to
calculate the URL of any file given its path relative to
`public`---extremely useful when writing page layout templates:

--------------------------------------------------------------------------------------
Local filename          Local URL                Reverse route
----------------------- ------------------------ -------------------------------------
`public/images/cat.jpg` `/assets/images/cat.jpg` `@routes.Assets.at("images/cat.jpg")`

`public/audio/meow.mp3` `/assets/audio/meow.mp3` `@routes.Assets.at("audio/meow.mp3")`
--------------------------------------------------------------------------------------

### Compiling Assets

Play uses the `sbt-web` build system to provide
an extensive and customisable range of build steps for static assets,
including:

 - RequireJS modules using the [sbt-rjs][link-sbt-rjs] plugin;
 - [asset fingerprinting][link-fingerprinting] using
   the [sbt-digest][link-sbt-digest] plugin;
 - compression using the [sbt-gzip][link-sbt-gzip] plugin;
 - common Javascript and CSS dependencies via
   the [WebJars][link-webjars] project.

See the [Play documentation on assets][docs-assets]
and the [sbt-web web site][link-sbt-web] for more information.
