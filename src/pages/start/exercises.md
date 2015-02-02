## Installing the Exercises

The exercises and sample code in this book
are all packaged with a copy of SBT.
All you need to get started are Git, a Java runtime,
and an Internet connection to download other dependencies.

Start by cloning the [Github repository](link-exercises) for the exercises:

~~~ bash
bash$ git clone https://github.com/underscoreio/essential-play-code.git

bash$ cd essential-play-code

dave@Jade ~/d/p/essential-play-code> git status
# On branch exercises...

bash$ ls -1
chapter1-hello
chapter2-calc
chapter2-chat
# And so on...
~~~

The repository has two branches, `exercises` and `solutions`,
each containing a set of self-contained Play projects in separate directories.
We have included one exercise to serve as an introduction to SBT.
Change to the `chapter1-hello` directory and start SBT
using the shell script provided:

~~~ bash
bash$ cd chapter1-hello

bash$ ./sbt.sh
# Lots of output here...
# The first run will take a while...

[app] $
~~~

<div class="callout callout-info">
*"Downloading the Internet"*

The first commands you run in SBT will cause it to
download various dependencies, including libraries for Play,
the Scala runtime, and even the Scala compiler.
This process can take a while and is affectionately known
to Scala developers as "downloading the Internet".

These files are only downloaded once,
after which SBT caches them on your system.
Be prepared for delays of up to a few minutes:

 - the first time you start SBT;
 - the first time you compile your code;
 - the first time you compile your unit tests.

Things will speed up considerably once these files are cached.
</div>

Once SBT is initialised, your prompt should change to "app",
which is the name of the Play project we've set up for you.
You are now interacting with SBT.
Compile the project using the `compile` command
to check everything is working:

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

### Other Exercises in this Book

The process you have used here is the same for each exercise in this book:

1.  change to the relevant exercise directory;
2.  start SBT;
3.  issue the relevant SBT commands to compile and run your code.

You will find complete solutions to each exercise in the `solutions` branch
of the repository.

<div class="callout callout-warning">
*Getting Help*

Resist the temptation to look at the solutions if you get stuck!
You *will* make mistakes when you first start programming Play applications,
but mistakes are the best way to teach yourself.

If you do get stuck, join our [Gitter chat room](https://gitter.im/underscoreio/scala)
to get help from the authors and other students.

Try to get the information you need to solve the immediate problem
without gaining complete access to the solution code.
You'll proceed slower this way but you'll learn a lot faster
and the knowledge will stick with you longer.

</div>
