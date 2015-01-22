## Installing SBT

Play uses a build system called SBT. We'll need to familiarise ourselves with this before we can start writing applcations. In this section we'll discuss what SBT is how to install it. In the next section we'll learn the basic commands required to use it.

### What Does SBT Do?

SBT provides a complete set of functionality for compiling and running Scala code, including fetching library dependencies, invoking the compiler, running unit tests, starting development web servers, and packaging applications for release.

SBT is distributed as a single executable JAR that uses several account-wide *caches* to store the files it needs. It automatically downloads any dependencies is requires (libraries, build plugins, and so on) using information in configuration files. The only pre-requisite we need to run SBT is a JVM.

Dependency management is complicated by the fact that different Scala projects depend on *different versions of SBT*. For this reason, the SBT executable is actually a *launcher* that downloads, caches, and runs the correct versions of Scala and SBT for the current project. Everything we need is fetched and cached based on our project configuration!

This caching behaviour allows us to install SBT in a number of ways. We can use a single system-wide command for all of the projects on our machine, or ship a launcher with our codebase for maximum portabilty. We can even mix and match approaches because each copy of SBT we use will reference on the same standard caches.

Despite all of this convenience, there are two important drawbacks that we should be aware of when using SBT:

 1. the first time we build a project we must be connected to the Internet for SBT to download all of its dependencies;

 2. the first build of a project may consequently take a long time.

<div class="callout callout-warning">
*Default cache locations*

SBT is implemented on top of a dependency manager called *Ivy*. Downloaded library dependencies are cached as JARs under `${user.home}/.ivy2`. The SBT launcher also uses `${user.home}/.sbt` to store configuration files, account-wide plugins, and temporary caches.
</div>

### Flavours of SBT

As we saw in the previous section, there are various ways to install SBT. Here are some of the options available, any of which is suitable for completing the exercises in this book:

- **System-wide vanilla SBT**---We can install a system-wide SBT launcher using the instructions on [the SBT web site](link-sbt-install). Linux and OS X users can download copies via package managers such as Apt, MacPorts, and Homebrew.

- **Project-local vanilla SBT**---Because the SBT launcher is a single executable JAR, we can bundle it with our codebase for maximum portability. This is the approach we used for the exercises and solutions in this book. ZIP downloads of the required files are available from the [SBT web site](link-sbt-install).

- **Typesafe Activator**---Activator, available from [Typesafe's web site](link-activator-install), is a tool for getting started quickly with the Typesafe Stack. The `activator` command is essentially SBT bundled with a system-wide plugin for generating new projects from pre-defined templates.

- **"SBT Extras" script**---Paul Philips released an excellent shell script that acts as a front-end for SBT. The script does the bootstrapping process of detecting Scala and SBT versions without requiring a launcher JAR. Linux and OS X users can download the script from [Paul's Github page](link-paulp-sbt-install).

- **Legacy Play build tool**---Older downloads from [http://playframework.com](http://playframework.com) shipped with a built-in `play` command that was also an alias for SBT, albeit with a non-standard Ivy configuration. Newer versions of Play are shipped with Activator instead. *We recommend replacing this legacy command with one of the other options described above.*

### Getting Started With This Book

The exercises and sample code in this book are all packaged using project-local copies of SBT. To grab the exercises, simply clone our [Github repository](link-exercises) and run SBT using the `sbt.sh` or `sbt.bat` scripts provided:

~~~ bash
bash$ git clone https://github.com/underscoreio/essential-play-code.git

bash$ cd essential-play-code

bash$ ./sbt.sh
# Lots of output here...
# The first run will take a while...

[app] $
~~~

Your prompt should change to "app", which is the name of the Play project we've set up. You are now interacting with SBT. Compile the project using the `compile` command to check everything is working:

~~~ bash
[app] $ compile
# Lots of output here...
# The first run will take a while...
[info] Updating {file:/Users/dave/dev/projects/essential-play-code/}app...
[info] Resolving jline#jline;2.12 ...
[info] Done updating.
[info] Compiling 3 Scala sources and 1 Java source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[success] Total time: 7 s, completed 13-Jan-2015 11:15:39

[app] $
~~~

If the project compiles successfully, try running it. Enter `run` to start a development web server, and access it at [http://localhost:9000](http://localhost:9000) to test out the app:

~~~ bash
[app] $ run

--- (Running the application from SBT, auto-reloading is enabled) ---

[info] play - Listening for HTTP on /0:0:0:0:0:0:0:0:9000

(Server started, use Ctrl+D to stop and go back to the console...)

# Play waits until we open a web browser...
[info] play - Application started (Dev)
~~~

If everything worked correctly you should see the message `"Hello world!"` in your browser. Congratulations---you have run your first Play web application!
