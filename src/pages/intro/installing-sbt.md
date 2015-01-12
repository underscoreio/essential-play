## Installing SBT

Play uses a build tool called the *Scala Build Tool (SBT)*. We'll need to familiarise ourselves with this tool before we can start writing applcations. In this section we'll discuss how SBT works and show you how to install it.

### How Does SBT Work?

At its core SBT is an executable JAR file that compiles and runs our code. This comprises several tasks, including  fetching library dependencies, compiling our code, running unit tests, running a development web server, and packaging everything for release.

SBT uses several *caches* to store the files it needs. Any library dependencies and build plugins referred to in our projects are automatically downloaded and cached in a system-wide directory (`~/.ivy2` by default). This saves on hard disk space by ensuring that we only store one copy of each version of each library we use in our Scala code.

Different projects can depend on different versions of SBT, so the command we run on the command line is actually a *launcher* that downloads, caches, and runs the correct versions of Scala and SBT. *Everything* is fetched and cached based on our project configuration!

Because everything is versioned and cached by the SBT launcher, we can use a single system-wide command for all of the projects on our machine. We can equally ship a launcher JAR with our codebase to any developer who doesn't already have Scala set up---all they need to use our code is a Java Virtual Machine.

This downloading-and-caching approach has obvious advantages in terms of saved hard disk space, but it also has two important drawbacks:

 1. the first time we build a project we must be connected to the Internet for SBT to download all of its transitive dependencies;

 2. the first build of any project can consequently take a long time.

### Flavours of SBT

SBT has been bundled and packaged into a number of different projects in the Scala development space. Here are some options for installing SBT:

- **System-wide vanilla SBT**---We can install a system-wide SBT command using the instructions on [the SBT web site](link-sbt-install). This is all we need to get started using Scala.

- **Project-local vanilla SBT**---The SBT launcher is nothing more than a small executable JAR file that we can bundle with our codebase. This is useful for sharing code with non-Scala developers---all they need to get started is a JVM and an internet connection.

- **Typesafe Activator**---Activator, available from [Typesafe's web site](link-activator-install), is a tool for getting started quickly with the Typesafe Stack. The `activator` command is simply a copy of SBT bundled with a system-wide plugin for generating new projects from pre-defined templates.

- **"SBT Extras" script**---Paul Philips released a shell script that acts as a front-end for SBT, bootstrapping it from nothing. You can download the script from [Paul's Github page](link-paulp-sbt-install). We have found this to be the most reliable way of launching SBT in our projects.

- **Legacy Play build tool**---Older downloads from [http://playframework.com](http://playframework.com) shipped with a built-in `play` command that was also an alias for SBT. Newer versions of Play are shipped with Activator instead. If you are using this legacy command we recommend replacing it with one of the other options described above.

### Getting Started

The exercises and sample code in this book are all packaged using project-local copies of SBT. All you need to run them is a Java Virtual Machine.

To grab the exercises, clone our [Github repository](link-exercises) and run the project-local copy of SBT using the shell `sbt.sh` or `sbt.bat` script provided:

~~~ bash
bash$ git clone https://github.com/underscoreio/essential-play-code.git

bash$ cd essential-play-code

bash$ ./sbt.sh
# Lots of output here...
# The first run will take a while...

[app] $
~~~

Your prompt should change to "app", which is the name of the project we've set up for you. You are now interacting with SBT. Compile and run the project using the `run` command to test everything is working:

~~~ bash
[app] $ run
# Lots of output here...
# The first run will take a while...
--- (Running the application from SBT, auto-reloading is enabled) ---

2015-01-12 14:46:33,493 DEBUG org.jboss.netty.channel.socket.nio.SelectorUtil  - Using select timeout of 500
2015-01-12 14:46:33,494 DEBUG org.jboss.netty.channel.socket.nio.SelectorUtil  - Epoll-bug workaround enabled = false
2015-01-12 14:46:33,550 INFO  play  - Listening for HTTP on /0:0:0:0:0:0:0:0:9000

(Server started, use Ctrl+D to stop and go back to the console...)
~~~

Once you see the message "Listening for HTTP on /0:0:0:0:0:0:0:0:9000", open up [http://localhost:9000](http://localhost:9000) in your web browser to see the application running. Play will compile your code, after which you should see the message "Hello world!"

Congratulations! You've run your first Play web application! In the next section we'll discuss the most important commands for interacting with SBT, before diving in to Play itself in the next chapter.
