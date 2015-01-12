## Building Play Projects Using SBT

In this section we will cover the directory structure of Play project and the main commands used to build then, run them, and package them for deployment.

### Interative an Batch Modes

Running SBT with no arguments start its *interactive mode*. We are presented with an SBT command prompt where we can enter commands such as `compile`, `run`, and `clean` to build our code. Pressing `Ctrl+D` quits SBT when we're done:

~~~ bash
bash$ ./sbt.sh

[app] $ compile
# SBT compiles our code and we end up back in SBT...

[app] $ ⏎ # Ctrl+D quits back to the OS command prompt

bash$
~~~

<div class="callout callout-info">
*SBT command prompts*

The default SBT command prompt is a single echelon:

~~~ bash
>
~~~

The Play plugin changes this to the name of the project surrounded by square brackets:

~~~ bash
[app] $
~~~

You may find the prompt changing as you switch back and forth between Play projects and vanilla Scala projects. The prompts are equivalent except in a few cases where Play adds new commands or overrides SBT's default behaviour.
</div>

We can run SBT in *batch mode* by issuing commands as arguments at the system command prompt. SBT executes the commands immediately and then exits:

~~~ bash
bash$ ./sbt.sh compile
# SBT compiles our code and we end up back on the OS command prompt...

bash$
~~~

Batch mode is useful for continuous integration and delivery. However, it is faster to use interactive mode during development. SBT stays running between commands in interactive mode, so we avoid the time taken to start a new JVM each time we issue a command.

### SBT Commands

The table below contains a summary of the most useful SBT commands. We will cover command each in detail below.

SBT automatically executes the depdendencies of a command in addition to the command itself. For example, if we enter the `test` command, SBT will download and cache all library dependencies, compile the application, and compile and run the unit tests.

------------------------------------------------------------------------------------------------------------
SBT Command                    Purpose                               Dependencies
------------------------------ ------------------------------------- ---------------------------------------
`compile`                      Compiles application code             Resolve and cache library dependencies

`run`                          Runs application in development mode, `compile`
                               continuously recompiles on demand

`console`                      Starts an interactive Scala prompt    `compile`

`test:compile`                 Compiles all unit tests               `compile`

`test`                         Compiles and runs all unit tests      `test:compile`

`testOnly com.example.MyClass` Compiles and runs specific unit tests `test:compile`

`stage`                        Gathers all dependencies into a       `compile`
                               single stand-alone directory

`dist`                         Gathers staged files into a ZIP file  `stage`

`clean`                        Deletes temporary build files         None

------------------------------------------------------------------------------------------------------------

#### Compiling and Cleaning Code

The `compile` and `test:compile` commands compile code *incrementally*---they check to see which source files have changed recently and only compile the files they need to. This behaviour speeds up builds significantly during development.

We can use the `clean` command if we ever want to re-build from scratch. Clean builds tend to take significantly longer than incremental ones.

#### Continuous Compilation

We can also prefix either of these commands with a *tilde* character `~` to ask SBT to watch our code and recompile whenever we change a source file. This is extremely useful to get instant feedback from the compiler during development.

#### Running in Development Mode

SBT's default `run` command compiles and runs the application. However, Play replaces the default behaviour with something far more advanced.

Issuing the `run` command in a Play project starts a development web server on `localhost:9000` and watches for incoming connections. Every time the web server receives a request, it checks whether our code needs compiling, recompiles it if necessary, and sends the request to the newly compiled codebase.

Play's `run` command is the only command in SBT that continuously watches and recompiles code by default. Most other commands need to be prefixed with `~` to run in continuous mode.

#### Running Unit Tests

The `test` command compiles and runs the unit tests for the application, whereas `testOnly` only runs a single test suite. `testOnly` is obviously a lot faster than `test` and is useful when writing new tests on top of an already passing test codebase.

As with `compile` and `test:compile`, both of these commands can run in continuous mode by prefixing them with a `~`.

#### Packaging and Deploying the Application

The `stage` command bundles the compiled application and all of its dependencies into a single directory under `target/universal/stage`. The command creates a shell script under `target/universal/stage/bin` for running the application with the correct classpath and JVM options.

The `stage` directory can be `rsynced` onto a remote server and used to run the application in a staging or production environment. The `dist` command creates a ZIP archive of the staging directory to make it even easier to distribute the compiled code.

### Play Directory Structure

TODO