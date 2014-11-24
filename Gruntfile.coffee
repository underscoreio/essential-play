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
      all:
        options:
          paths: [
            "node_modules"
            "src/css"
          ]
          compress: minify
          yuicompress: minify
        files:
          "dist/html/css/screen.css" : "src/css/screen.less"
          "dist/html/css/print.css"  : "src/css/print.less"

    browserify:
      all:
        src:  "src/js/main.coffee"
        dest: "dist/html/js/main.js"
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
        ]
      js:
        files: [
          "src/js/**/*"
        ]
        tasks: [
          "browserify"
        ]
      templates:
        files: [
          "src/templates/**/*"
        ]
        tasks: [
          "copy"
          "pandoc"
        ]
      pages:
        files: [
          "src/pages/**/*"
        ]
        tasks: [
          "copy"
          "pandoc"
        ]

    connect:
      server:
        options:
          port: 4000
          base: 'dist/html'

  grunt.renameTask "watch", "watchImpl"

  grunt.registerTask "pandoc", "Run pandoc", (target) ->
    done   = this.async()

    grunt.verbose.subhead("pandoc")

    switch target
      when "pdf"
        target   = "dist/pdf/essential-play.pdf"
        template = "src/templates/template.tex"
      when "html"
        output   = "dist/html/index.html"
        template = "src/templates/template.html"

    command = joinLines """
      pandoc
      --smart
      --output=#{output}
      --template=#{template}
      --from=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block
      --latex-engine=xelatex
      --filter=src/filters/callout.coffee
      --filter=src/filters/columns.coffee
      --variable=papersize:a4paper
      --variable=lof:true
      --variable=lot:true
      --chapters
      --number-sections
      --table-of-contents
      --highlight-style tango
      --standalone
      --self-contained
      src/meta/metadata.yaml
      #{pandocSources}
    """

    grunt.log.write("Running: #{command}")

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

  grunt.registerTask "html", [
    "less"
    "browserify"
    "pandoc:html"
  ]

  grunt.registerTask "pdf", [
    "pandoc:pdf"
  ]

  grunt.registerTask "serve", [
    "build"
    "connect:server"
    "watchImpl"
  ]

  grunt.registerTask "watch", [
    "html"
    "connect:server"
    "watchImpl"
    "serve"
  ]
