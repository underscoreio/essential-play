#global module:false

path    = require 'path'
process = require 'child_process'

"use strict"

module.exports = (grunt) ->
  minify = grunt.option('minify') ? false

  grunt.loadNpmTasks "grunt-browserify"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-exec"
  grunt.loadNpmTasks "grunt-css-url-embed"

  joinLines = (lines) ->
    lines.split(/[ \r\n]+/).join(" ")

  pandocSources = joinLines """
    src/pages/start/foreword.md
    src/pages/basics/index.md
    src/pages/basics/actions.md
    src/pages/basics/routes.md
    src/pages/basics/requests.md
    src/pages/basics/results.md
    src/pages/basics/failure.md
    src/pages/html/index.md
    src/pages/html/templates.md
    src/pages/html/forms.md
    src/pages/html/form-templates.md
    src/pages/json/index.md
    src/pages/json/values.md
    src/pages/json/writes.md
    src/pages/json/reads.md
    src/pages/json/formats.md
    src/pages/json/custom1.md
    src/pages/json/custom2.md
    src/pages/json/custom3.md
    src/pages/json/failure.md
    src/pages/async/index.md
    src/pages/async/futures.md
    src/pages/async/executioncontexts.md
    src/pages/async/actions.md
    src/pages/async/ws.md
    src/pages/async/failure.md
    src/pages/links.md
  """

  grunt.initConfig
    less:
      main:
        options:
          paths: [
            "node_modules"
            "src/css"
          ]
          compress: minify
          yuicompress: minify
        files:
          "dist/temp/main.noembed.css" : "src/css/main.less"

    cssUrlEmbed:
      main:
        options:
          baseDir: "."
        files:
          "dist/temp/main.css" : "dist/temp/main.noembed.css"

    browserify:
      main:
        src:  "src/js/main.coffee"
        dest: "dist/temp/main.js"
        cwd:  "."
        options:
          watch: false
          transform: if minify
            [ 'coffeeify', [ 'uglifyify', { global: true } ] ]
          else
            [ 'coffeeify' ]
          browserifyOptions:
            debug: false
            extensions: [ '.coffee' ]

    watchImpl:
      options:
        livereload: true
      css:
        files: [
          "src/css/**/*"
        ]
        tasks: [
          "less"
          "cssUrlEmbed"
          "pandoc:html"
        ]
      js:
        files: [
          "src/js/**/*"
        ]
        tasks: [
          "browserify"
          "pandoc:html"
        ]
      templates:
        files: [
          "src/templates/**/*"
        ]
        tasks: [
          "pandoc:html"
          "pandoc:pdf"
          "pandoc:epub"
        ]
      pages:
        files: [
          "src/pages/**/*"
        ]
        tasks: [
          "pandoc:html"
          "pandoc:pdf"
          "pandoc:epub"
        ]
      metadata:
        files: [
          "src/meta/**/*"
        ]
        tasks: [
          "pandoc:html"
          "pandoc:pdf"
          "pandoc:epub"
        ]

    exec:
      zip:
        cmd: "zip essential-play.zip essential-play.pdf essential-play.html essential-play.epub"
        cwd: "dist"

    connect:
      server:
        options:
          port: 4000
          base: 'dist'

  grunt.renameTask "watch", "watchImpl"

  grunt.registerTask "pandoc", "Run pandoc", (target) ->
    done = this.async()

    target ?= "html"

    distPath = "dist/" + target + "/"
    output   = distPath + "essential-play." + target
    grunt.file.mkdir(distPath)

    switch target
      when "pdf"
        output   = "--output=dist/essential-play.pdf"
        template = "--template=src/templates/template.tex"
        filters  = joinLines """
                     --filter=src/filters/pdf/callout.coffee
                     --filter=src/filters/pdf/columns.coffee
                   """
      when "html"
        output   = "--output=dist/essential-play.html"
        template = "--template=src/templates/template.html"
        filters  = joinLines """
                     --filter=src/filters/html/tables.coffee
                   """
      when "epub"
        output   = "--output=dist/essential-play.epub"
        template = "--epub-stylesheet=dist/temp/main.css"
        filters  = ""
      when "json"
        output   = "--output=dist/essential-play.json"
        template = ""
        filters  = ""

      else
        grunt.log.error("Bad pandoc format: #{target}")

    command = joinLines """
      pandoc
      --smart
      #{output}
      #{template}
      --from=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block
      --latex-engine=xelatex
      #{filters}
      --variable=papersize:a4paper
      --variable=lof:true
      --variable=lot:true
      --variable=geometry:margin=.75in        \
      --chapters
      --number-sections
      --table-of-contents
      --highlight-style tango
      --standalone
      --self-contained
      src/meta/metadata.yaml
      #{pandocSources}
    """

    grunt.log.debug("Running: #{command}")

    pandoc = process.exec(command)

    pandoc.stdout.on 'data', (d) ->
      grunt.log.write(d)
      return

    pandoc.stderr.on 'data', (d) ->
      grunt.log.error(d)
      return

    pandoc.on 'error', (err) ->
      grunt.log.error("Failed with: #{err}")
      done(false)

    pandoc.on 'exit', (code) ->
      if code == 0
        grunt.verbose.subhead("pandoc exited with code 0")
        done()
      else
        grunt.log.error("pandoc exited with code #{code}")
        done(false)

    return

  grunt.registerTask "json", [
    "pandoc:json"
  ]

  grunt.registerTask "html", [
    "less"
    "cssUrlEmbed"
    "browserify"
    "pandoc:html"
  ]

  grunt.registerTask "pdf", [
    "pandoc:pdf"
  ]

  grunt.registerTask "epub", [
    "less"
    "cssUrlEmbed"
    "pandoc:epub"
  ]

  grunt.registerTask "all", [
    "less"
    "cssUrlEmbed"
    "browserify"
    "pandoc:html"
    "pandoc:pdf"
    "pandoc:epub"
  ]

  grunt.registerTask "zip", [
    "all"
    "exec:zip"
  ]

  grunt.registerTask "serve", [
    "build"
    "connect:server"
    "watchImpl"
  ]

  grunt.registerTask "watch", [
    "all"
    "connect:server"
    "watchImpl"
    "serve"
  ]

  grunt.registerTask "default", [
    "zip"
  ]
