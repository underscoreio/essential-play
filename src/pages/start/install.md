## Installing SBT

As you saw in the previous section,
we have bundled the exercises in this book
with the scripts and binaries you need to run SBT.
This is a great setup for our purposes,
but after you've finished this book you will want to
install SBT properly so you can work on your own applications.
In this section we will discuss the options available to you to do this.

### How Does SBT Work?

SBT relies heavily on account-wide caches to store project dependencies.
By default these caches are located in two folders:

 - `~/.sbt`---contains configuration files and account-wide SBT plugins;

 - `~/.ivy2`---contains library dependencies cached by library name
   and version number (similar to the `~/.m2` directory for Maven).

The JAR file we run to boot SBT is actually a *launcher*
(typically named `sbt-launch.jar`) that downloads and caches
the actual version of SBT we need for our project.
We can use the same launcher to build projects requiring
different versions of SBT and even Scala!

This means we are free to install SBT in a variety of different ways---or
even in *multiple* ways on the same computer---without
worrying about duplicate cached information.
The different installs will work together seamlessly
because they all use the same cached dependencies.

Despite all of this convenience, there are two important drawbacks
to be aware of:

 1. the first time we build a project we must be connected to the Internet
    for SBT to download the required dependencies;

 2. as we saw in the previous section,
    the first build of a project may take a long time.

### Flavours of SBT

SBT is available from an number of sources under a variety of different names.
Here the main options available, any of which is a
suitable start point for your own applications:

 -  **System-wide vanilla SBT**---We can install a system-wide
    SBT launcher using the instructions on [the SBT web site](link-sbt-install).
    Linux and OS X users can download copies via package managers
    such as Apt, MacPorts, and Homebrew.

 -  **Project-local vanilla SBT**---At its core the SBT launcher is
    as a single executable JAR. We can bundle this file with a project
    and create shell scripts to start it with the correct command line arguments.
    This is the approach used in the exercises and solutions for this book.
    ZIP downloads of the required files are available from the
    [SBT web site](link-sbt-install).

 -  **Typesafe Activator**---Activator, available from
    [Typesafe's web site](link-activator-install),
    is a tool for getting started with the Typesafe Stack.
    The `activator` command is actually just an alias for SBT,
    although the activator distribution comes pre-bundled with a
    global plugin for generating new projects from templates
    (the `activator new` command).

 -  **"SBT Extras" script**---Paul Philips released an excellent
    shell script that acts as a front-end for SBT.
    The script does the bootstrapping process of detecting
    Scala and SBT versions without requiring a launcher JAR.
    Linux and OS X users can download the script from
    [Paul's Github page](link-paulp-sbt-install).

 -  **Legacy Play build tool**---Older downloads from
    [http://playframework.com](http://playframework.com) shipped
    with a built-in `play` command that was also an alias for SBT.
    However, the old Play distributions configured SBT
    with non-standard cache directories that meant it
    did not play nicely with other installs.

    Newer versions of Play are shipped with Activator instead.
    *We recommend replacing legacy `play` tools with
    one of the other options described above.*
