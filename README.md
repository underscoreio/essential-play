Essential Play
--------------

Getting Started
---------------

Grunt is installed, if not you'll need to install Node and most likely brew, good luck.

Grunt - http://gruntjs.com is used to drive pandoc to build various content types - html, pdf and epub.

You'll need to install the grunt project dependencies the first time you check the project out:

~~~
brew install pandoc
npm install
~~~

Building
--------

Use the following commands to build the PDF and HTML versions respectively:

~~~
grunt pdf
grunt html
~~~

Output goes into the `dist` directory.
