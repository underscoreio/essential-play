## Directory Structure

Play projects use the following directory structure,
which is slightly different to the standard structure of an SBT project:

~~~ bash
root/
 +- app/
     +- assets/
 +- conf/
 +- logs/
 +- project/
 +- public/
 +- target/
 +- test/
 +- views/
~~~

Application code is stored in the following locations:

 - `app`---Scala application code;

 - `app/assets`---client assets for compilation by SBT
   (Javascript, Coffeescript, Less CSS, and so on);

 - `views`---Twirl templates for compilation by SBT;

 - `public`---static assets to be served by the application
   (HTML, Javascript, CSS, and so on);

 - `conf`---runtime configuration files to be bundled with the application
   (route configuration, logs, database, actor systems);

 - `test`---Scala unit tests.

SBT uses two directories to store additional files related to the build process:

 - `project`---configuration files and temporary files;

 - `target`---temporary directory used to store completed builds.

Most of our time in this book will be spent editing
Scala files  in the `app` and `test` directories
and the `routes` configuration file in the `conf` directory.
You can find out more about [the asset directories](docs-assets) and
[configuration files](docs-config) in the Play documentation.
