Essential Play
--------------

Getting Started
---------------

You'll need to install the grunt project dependencies the first time you check the project out:

~~~
brew install pandoc
npm install -g grunt-cli
npm install
~~~

Building
--------

Use the following commands to build a single format:

~~~
grunt pdf
grunt html
grunt epub
~~~

The default grunt behaviour is to build all formats:

~~~
grunt
~~~

All targets are placed in the `dist` directory.

Run the following to build all formats, start a web server to serve them,
and rebuild if you change any files:

~~~
grunt watch
~~~

Publishing a Preview
--------------------

The `grunt` command generates `essential-play-preview.pdf` but this does not include the full TOC.
To create a version of the preview with the full TOC:

~~~
$ cd  ..
$ git checkout https://github.com/d6y/toctastic
$ cd toctastic
$ sh eplay.sh
~~~

This will create `dist/essential-play-preview-with-full-toc.pdf`.

Upload this file to the Underscore S3 account, in the `book-sample` bucket.
It should have world-read permissions on it.
Check that you can download it from the book page to be sure.
