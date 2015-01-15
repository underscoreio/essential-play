## Installing SBT

Play uses a build tool called the *Scala Build Tool (SBT)*. We'll need to familiarise ourselves with this tool before we can start writing applcations. In this section we'll discuss what SBT is and show you how to install it. In the next section we'll learn a few basic commands and start using the tool.

### What Does SBT Do?

SBT is a tool that compiles and runs Scala code. This comprises several tasks including fetching library dependencies, running the compiler, running unit tests, starting development web servers, and packaging everything for release.

SBT is distributed as a single executable JAR that uses several account-wide *caches* to store the files it needs. It automatically downloads any project dependencies (libraries, build plugins, and so on) on demand based on information in configuration files. This allows us to get started with only JVM pre-installed on our machine. It also saves on hard disk space by ensuring that the minimum number of copies of each library are stored on our hard drive.

Dependency management is complicated by the fact that different projects can depend on *different versions of SBT*. For this reason, the command we run on the command line is actually a *launcher* that downloads, caches, and runs the correct versions of Scala and SBT for the current project. *Everything* is fetched and cached based on our project configuration!

SBT's caching behaviour allows us to install it in a number of ways. We can use a single system-wide command for all of the projects on our machine, or ship a launcher with each codebase we maintain. We can even mix and match the approaches because SBT always caches dependencies in the same standard locations. However, there are two important drawbacks that we should be aware of:

 1. the first time we build a project we must be connected to the Internet for SBT to download all of its dependencies;

 2. the first build of a project may consequently take a long time.

<div class="callout callout-warning">
**Default cache locations**

SBT is implemented on top of a dependency manager called *Ivy*. Downloaded dependencies are cached `${user.home}/.ivy2`. SBT also uses `${user.home}/.sbt` to store various configuration files.
</div>

### Flavours of SBT

SBT has been bundled and packaged into a number of different projects in the Scala ecosystem so you may already be aware of it under a different name. All of these tools interoperate, so here are some options for installing SBT:

- **System-wide vanilla SBT**---We can install a system-wide SBT launcher using the instructions on [the SBT web site](link-sbt-install). Linux and OS X users can download copies via package managers such as Apt, MacPorts, and Homebrew.

- **Project-local vanilla SBT**---Because the SBT launcher is a single executable JAR, we can bundle it with our codebase. This is useful for sharing code with non-Scala developers because they only need a JVM to get started. This is the approach we used for the exercises and solutions in this book.

- **Typesafe Activator**---Activator, available from [Typesafe's web site](link-activator-install), is a tool for getting started quickly with the Typesafe Stack. The `activator` command is essentially SBT bundled with a system-wide plugin for generating new projects from pre-defined templates.

- **"SBT Extras" script**---Paul Philips released an excellent shell script that acts as a front-end for SBT. The script does the bootstrapping process of detecting Scala and SBT versions without requiring a launcher JAR. Linux and OS X users can download the script from [Paul's Github page](link-paulp-sbt-install).

- **Legacy Play build tool**---Older downloads from [http://playframework.com](http://playframework.com) shipped with a built-in `play` command that was also an alias for SBT, albeit with a non-standard Ivy configuration. Newer versions of Play are shipped with Activator instead. If you are using this legacy command we recommend replacing it with one of the other options described above.

### Installing SBT for This Book

The exercises and sample code in this book are all packaged using project-local copies of SBT. All you need to run them is a Java Virtual Machine. To grab the exercises, clone our [Github repository](link-exercises) and run SBT using the `sbt.sh` or `sbt.bat` scripts provided:

~~~
bash$ git clone https://github.com/underscoreio/essential-play-code.git

bash$ cd essential-play-code

bash$ ./sbt.sh
# Lots of output here...
# The first run will take a while...

[app] $
~~~

Your prompt should change to "app", which is the name of the Play project we've set up for you. You are now interacting with SBT. Compile the project using the `compile` command to test everything is working:

~~~
[app] $ compile
# Lots of output here...
# The first run will take a while...
[info] Updating {file:/Users/dave/dev/projects/essential-play-code/}app...
[info] Resolving jline#jline;2.12 ...
[info] Done updating.
[info] Compiling 3 Scala sources and 1 Java source to /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[success] Total time: 7 s, completed 13-Jan-2015 11:15:39

[app] $
~~~

If the project compiles successfully, try running it. Enter `run` to start a development web server, and access it at [http://localhost:9000](http://localhost:9000) to test out the app:

~~~
[app] $ run

--- (Running the application from SBT, auto-reloading is enabled) ---

[info] play - Listening for HTTP on /0:0:0:0:0:0:0:0:9000

(Server started, use Ctrl+D to stop and go back to the console...)

# Play waits until we open a web browser...
[info] play - Application started (Dev)
~~~

If everything worked correctly you should see the message `"Hello world!"` in your browser. Congratulations! You've run your first Play web application!
