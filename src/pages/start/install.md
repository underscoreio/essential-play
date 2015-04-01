## Installing SBT

As we discussed in the previous section,
each exercise and solution is bundled with its own scripts and binaries for SBT.
This is a great setup for this book,
but after you've finished the exercises you will want to
install SBT properly so you can work on your own applications.
In this section we will discuss the options available to you to do this.

### How Does SBT Work?

SBT relies heavily on account-wide caches to store project dependencies.
By default these caches are located in two folders:

 - `~/.sbt` contains configuration files and account-wide SBT plugins; and

 - `~/.ivy2` contains cached library dependencies
   (similar to `~/.m2` for Maven).

SBT downloads dependencies on demand
and caches them for future use in `~/.ivy2`.
In fact, the JAR we run to boot SBT is actually a *launcher*
(typically named `sbt-launch.jar`) that downloads and caches
the correct versions of SBT and Scala needed for our project.

This means we can use a single launcher to compile and run
projects with different version requirements for libraries, SBT, and Scala.
We are can use separate launchers for each project,
or a single launcher that covers all projects on our development machine.
The shared caches allow multiple SBT launchers to work indepdently without conflict.

Despite the convenience of these account-wide caches,
they have two important drawbacks to be aware of:

 1. the first time we build a project we must be connected to the Internet
    for SBT to download the required dependencies; and

 2. as we saw in the previous section,
    the first build of a project may take a long time.

### Flavours of SBT

SBT is available from a number of sources under a variety of different names.
Here are the main options available,
any of which is a suitable starting point for your own applications:

 -  **System-wide vanilla SBT**---We can install a system-wide
    SBT launcher using the instructions on [the SBT web site](link-sbt-install).
    Linux and OS X users can download copies via package managers
    such as Apt, MacPorts, and Homebrew.

 -  **Project-local vanilla SBT**---We can bundle the SBT launcher JAR with a project
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

<div class="callout callout-danger">
*Legacy Play Distributions*

Older downloads from [http://playframework.com](link-play) shipped
with a built-in `play` command that was also an alias for SBT.
However, the old Play distributions configured SBT
with non-standard cache directories that meant it
did not play nicely with other installs.

We recommend replacing any copies of the legacy `play` command
with one of the other options described above.
Newer versions of Play are shipped with Activator,
which interoperates well with other
locally installed copies of SBT.
</div>
