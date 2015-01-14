## Using SBT with Play

In this section we will cover the main SBT commands needed to compile, run, test, and deploy a Play project. Some of these commands are standard to vanilla SBT while others are customised by Play. In this section we will concentrate on *what* the commands are and how they work. In the next section we will discuss *how* Play is changing the defaults.

### Interative and Batch Modes

SBT can be started in two modes: *interactive mode* and *batch mode*. Batch mode is useful for continuous integration and delivery, while interactive mode is faster and more convenient for use in development.

We start interactive mode be running SBT with no command line arguments. SBT displays a command prompt where we can enter commands such as `compile`, `run`, and `clean` to build our code. Pressing `Ctrl+D` quits SBT when we're done:

~~~
bash$ ./sbt.sh

[app] $ compile
# SBT compiles our code and we end up back in SBT...

[app] $ ⏎ # Ctrl+D quits back to the OS command prompt

bash$
~~~

We start batch mode by issuing commands as arguments when starting SBT. SBT executes the commands immediately and then exits back to the OS. The commands -- `compile`, `run`, `clean` and so on -- are the same in both modes:

~~~
bash$ ./sbt.sh compile
# SBT compiles our code and we end up back on the OS command prompt...

bash$
~~~

<div class="callout callout-info">
**The SBT command prompt**

The default SBT command prompt is a single echelon:

~~~
>
~~~

Play changes this to the name of the project surrounded by square brackets:

~~~
[app] $
~~~

You will find the prompt changing as you switch back and forth between Play projects and vanilla Scala projects. The prompts are equivalent except in a few cases where Play adds new commands or overrides SBT's default behaviour.
</div>

### Common SBT Commands

The table below contains a summary of the most useful SBT commands for working with Play. Each command is covered in more detail below.

Note that many commands have other commands as dependencies: `compile` depends on `update`, `run` depends on `compile`, and so on. SBT automatically executes the dependencies of a command in addition to the command itself. For example, we don't have to run `update` before we run `compile` -- SBT will do this for us automatically.

-------------------------------------------------------------------------------------------------------------
SBT Command                    Purpose                               Notes and Dependencies
------------------------------ ------------------------------------- ----------------------------------------
`update`                       Resolves and caches library           No dependencies
                               dependencies

`compile`                      Compiles application code             Depends on `update`

`run`                          Runs application in development mode, Depends on `compile`
                               continuously recompiles on demand

`console`                      Starts an interactive Scala prompt    Depends on `compile`

`test:compile`                 Compiles all unit tests               Depends on `compile`

`test`                         Compiles and runs all unit tests      Depends on `test:compile`

`testOnly foo.Bar`             Compiles and runs unit tests          Depends on `test:compile`
                               defined in the class `foo.Bar`

`stage`                        Gathers all dependencies into a       Depends on `compile`
                               single stand-alone directory

`dist`                         Gathers staged files into a ZIP file  Depends on `stage`

`clean`                        Deletes temporary build files         No dependencies
                               under `${projecthome}/target`

`eclipse`                      Generates Eclipse project files       Requires the `sbt-eclipse` plugin

-------------------------------------------------------------------------------------------------------------

### Compiling and Cleaning Code

The `compile` and `test:compile` commands compile our application code and unit tests respectively. The `clean` command deletes the generated class files again in case we want to rebuild from scratch (we don't normally need to do this).

Let's clean the example project from the previous section and recompile the code as an example.

~~~ scala
bash$ ./sbt.sh
[info] Loading project definition from ↩
       /Users/dave/dev/projects/essential-play-code/project
[info] Set current project to app (in build file:/.../essential-play-code/)

[app] $ clean
[success] Total time: 0 s, completed 13-Jan-2015 11:15:32

[app] $ compile
[info] Updating {file:/Users/dave/dev/projects/essential-play-code/}app...
[info] Resolving jline#jline;2.12 ...
[info] Done updating.
[info] Compiling 3 Scala sources and 1 Java source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[success] Total time: 7 s, completed 13-Jan-2015 11:15:39

[app] $
~~~

SBT tells us how many Scala and Java source files it compiled and how long compilation took---7 seconds in this case! Fortunately we normally don't need to wait this long. The `compile` and `test:compile` commands are *incremental*---they only recompile files that have changed since the last time we compiled the code. We can see the effect of incremental compilation by changing our application and running `compile` again. Open `app/controllers/AppController.scala` in an editor and change the `"Hello World!"` line to greet you by name:

~~~ scala
package controllers

import play.api.Logger
import play.api.Play.current
import play.api.mvc._

import models._

object AppController extends Controller {
  def index = Action { request =>
    Ok("Hello Dave!")
  }
}
~~~

Now re-run the `compile` command:

~~~
[app] $ compile
[info] Compiling 1 Scala source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[success] Total time: 1 s, completed 13-Jan-2015 12:26:16

[app] $
~~~

One Scala file compiled in one second. Much better!

Another reason our first `compile` command was slow was because a lot of time was spent loading the Scala compiler for the first time. If we keep the SBT console open in interactive mode, subsequent `compile` commands become much faster.

### Continuous Compilation

We can prefix any SBT command with a *tilde* character -- `~` -- to ask SBT to watch our code and recompile it whenever we change a source file. Type `~compile` at the prompt to see this in action:

~~~
[app] $ ~compile
[success] Total time: 0 s, completed 13-Jan-2015 12:31:09
1. Waiting for source changes... (press enter to interrupt)
~~~

SBT tells us it is "waiting for source changes". Now, whenever we edit a source file it will be automatically recompiled.

Let's see this by introducing a compilation error to `AppController.scala`. Open the source file again and delete the closing double quote character from `"Hello Name!"`. As soon as we save the file we see the following in SBT:

~~~
[info] Compiling 1 Scala source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[error] /Users/dave/dev/projects/essential-play-code/app/ ↩
        controllers/AppController.scala:11: unclosed string literal
[error]     Ok("Hello Dave!)
[error]        ^
[error] /Users/dave/dev/projects/essential-play-code/app/ ↩
        controllers/AppController.scala:12: ')' expected but '}' found.
[error]   }
[error]   ^
[error] two errors found
[error] (compile:compile) Compilation failed
[error] Total time: 0 s, completed 13-Jan-2015 12:32:45
2. Waiting for source changes... (press enter to interrupt)
~~~

The compiler has picked up the error and produced some error messages as a result. If we fix the error again and save the file, the error messages go away:

~~~
[success] Total time: 0 s, completed 13-Jan-2015 12:33:55
3. Waiting for source changes... (press enter to interrupt)
~~~

Watch mode is extremely useful for getting instant feedback during development. Simply press *Enter* when you're done to return to the SBT command prompt.

<div class="callout callout-info">
**Watch mode**

We can run any SBT command in watch mode by prefixing it with a `~` character. For example:

 - `~compile` watches our code and recompiles it whenever we change a file;
 - `~test` watches our code and reruns the unit tests whenever we change a file;
 - `~dist` watches our code and builds a new distributable ZIP archive whenever we change a file.

This behaviour is built into SBT and works prrespectively of whether we're using Play.
</div>

### Running a Development Web Server

SBT's built-in `run` command compiles and runs our application. Play replaces this default with a more advanced command that starts a development web server, watches for incoming connections, and recompiles our code (if required) whenever an incoming request is received.

Let's see this in action. First `clean` the codebase, then enter `run` at the SBT prompt. SBT starts up a web server on `/0:0:0:0:0:0:0:0:9000` (which means `localhost:9000` in IPv6-speak) and waits for a browser to connect:

~~~
[app] $ clean
[success] Total time: 0 s, completed 13-Jan-2015 12:44:07
[app] $ run
[info] Updating {file:/Users/dave/dev/projects/essential-play-code/}app...
[info] Resolving jline#jline;2.12 ...
[info] Done updating.

--- (Running the application from SBT, auto-reloading is enabled) ---

[info] play - Listening for HTTP on /0:0:0:0:0:0:0:0:9000

(Server started, use Ctrl+D to stop and go back to the console...)
~~~

Open up `http://localhost:9000` in your web browser and watch the SBT console to see what happens. Play receives the incoming request and recompiles and runs the application to respond:

~~~
[info] Compiling 3 Scala sources and 1 Java source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.11/classes...
[info] play - Application started (Dev)
~~~

If we reload the web page without changing the application, Play simply serves up the response again. However, if we change a source file and reload the page, Play recompiles the code before responding.

The `run` command is a great way to get instant feedback when developing an application. However, we have to send a request to the web browser to get Play to recompile the code. Sometimes using `~compile` or `~test` can be a more efficient way of working. It depends on how much code we're rewriting and how many compile errors we are likely to introduce during coding.

#### Running Unit Tests

The `test` and `testOnly` commands are used to run unit tests. `test` runs all unit tests for the application, whereas `testOnly` only runs a single test suite. Let's use the `test` command to run the tests for the sample application:

~~~
[app] $ test
[info] Compiling 1 Scala source to ↩
       /Users/dave/dev/projects/essential-play-code/target/scala-2.10/test-classes...
[info] ApplicationSpec:
[info] AppController
[info] - must respond with a friendly message
[info] ScalaTest
[info] Run completed in 934 milliseconds.
[info] Total number of tests run: 1
[info] Suites: completed 1, aborted 0
[info] Tests: succeeded 1, failed 0, canceled 0, ignored 0, pending 0
[info] All tests passed.
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] Total time: 2 s, completed 14-Jan-2015 14:02:45

[app] $
~~~

As this is the first time we've run the tests, SBT starts by compiling the test suite. It would also compile the application if we hadn't done that already. SBT then runs the tests, which contain a single test suite `controllers.AppControllerSpec` with a single test that checks whether our greeting starts with the word `"Hello"`.

We don't have many tests for our sample application so testing the app is fast. If we had lots of test suites, we could focus on a single suite using the `testOnly` command. `testOnly` takes the fully qualified class name of the desired suite as an argument:

~~~
[app] $ testOnly controllers.AppControllerSpec
[info] ScalaTest
[info] Run completed in 44 milliseconds.
[info] Total number of tests run: 0
[info] Suites: completed 0, aborted 0
[info] Tests: succeeded 0, failed 0, canceled 0, ignored 0, pending 0
[info] No tests were executed.
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for test:testOnly
[success] Total time: 1 s, completed 14-Jan-2015 14:06:42

[app] $
~~~

As with `compile`, both of these commands can run in watch mode by prefixing them with a `~`. Whenever we change and save a file, SBT will recompile it and rerun our tests for us.

### Packaging and Deploying the Application

The `stage` command bundles the compiled application and all of its dependencies into a single directory under the directory `target/universal/stage`. Let's run the `stage` command to see this in action:

~~~
[app] $ stage
[info] Packaging /Users/dave/dev/projects/essential-play-code/ ↩
       target/scala-2.10/app_2.10-0.1-SNAPSHOT-sources.jar ...
[info] Done packaging.
[info] Packaging /Users/dave/dev/projects/essential-play-code/ ↩
       target/scala-2.10/app_2.10-0.1-SNAPSHOT.jar ...
[info] Main Scala API documentation to /Users/dave/dev/projects/ ↩
       essential-play-code/target/scala-2.10/api...
[info] Done packaging.
[info] Wrote /Users/dave/dev/projects/essential-play-code/ ↩
       target/scala-2.10/app_2.10-0.1-SNAPSHOT.pom
[info] Packaging /Users/dave/dev/projects/essential-play-code/ ↩
       target/app-0.1-SNAPSHOT-assets.jar ...
[info] Done packaging.
model contains 10 documentable templates
[info] Main Scala API documentation successful.
[info] Packaging /Users/dave/dev/projects/essential-play-code/ ↩
       target/scala-2.10/app_2.10-0.1-SNAPSHOT-javadoc.jar ...
[info] Done packaging.
[success] Total time: 1 s, completed 14-Jan-2015 14:08:14

[app] $
~~~

Now press `Ctrl+D` to quit SBT and take a look at the package created by the `stage` command:

~~~
bash$ ls -l target/universal/stage/
total 0
drwxr-xr-x   4 dave  staff   136 14 Jan 14:11 bin
drwxr-xr-x   3 dave  staff   102 14 Jan 14:11 conf
drwxr-xr-x  44 dave  staff  1496 14 Jan 14:11 lib
drwxr-xr-x   3 dave  staff   102 14 Jan 14:08 share

bash$ ls -l target/universal/stage/bin
total 40
-rwxr--r--  1 dave  staff  12210 14 Jan 14:11 app
-rw-r--r--  1 dave  staff   6823 14 Jan 14:11 app.bat
~~~

SBT has created a directory `target/universal/stage` containing all the dependencies we need to run our application. It has also created two executable scripts under `target/universal/stage/bin` to run the application from the command prompt. If we run one of these scripts, the app starts up and allows us to connect as usual.

~~~
bash$ target/universal/stage/bin/app
Play server process ID is 22594
[info] play - Application started (Prod)
[info] play - Listening for HTTP on /0:0:0:0:0:0:0:0:9000
~~~

The contents of `target/universal/stage` can be copied onto a remote web server and run as a standalone application. We can use standard Unix commands such as `rsync` and `scp` to achieve this. Sometimes, however, it is more convenient to have an archive to distribute. We can create this using the `dist` command:

~~~
[app] $ dist
[info] Wrote /Users/dave/dev/projects/essential-play-code/ ↩
       target/scala-2.10/app_2.10-0.1-SNAPSHOT.pom
[info]
[info] Your package is ready in /Users/dave/dev/projects/ ↩
       essential-play-code/target/universal/app-0.1-SNAPSHOT.zip
[info]
[success] Total time: 2 s, completed 14-Jan-2015 14:15:50
~~~

The contents of the application archive are the same as the contents of the `target/universal/stage` directory.

### Setting Up IDEs

**Eclipse**---The sample SBT project includes an SBT plugin called `sbt-eclipse` that generates project files for Eclipse. Run the `eclipse` command to see this in action:

~~~
[app] $ eclipse
[info] About to create Eclipse project files for your project(s).
[info] Successfully created Eclipse project files for project(s):
[info] app

[app] $
~~~

Now start Eclipse and import your SBT project using **File menu > Import... > General > Existing files into workspace** and select the root directory of the project source tree in the *Select root directory* field. Click *Finish* to add a project called `app` to the Eclipse workspace.

**Intellij IDEA integration**---Newer versions of the Scala plugin for Intellij IDEA support direct import of SBT projects from within the IDE. Choose **File menu > Import... > SBT** and select the root directory of the project source tree. The import wizard will do the rest automatically.
