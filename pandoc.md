Pandoc Notes

Right so, this is okay as a starting point:

pandoc -S                               \
          -o essential-play.pdf         \
          --table-of-contents           \
          --toc-depth=4                 \
          --from=markdown+multiline_tables+fenced_code_blocks+fenced_code_attributes                 \
          --epub-stylesheet ./essential-play/css/print.css \
pandoc/title.txt                      \
src/pages/index.md                    \
src/pages/basics/index.md             \
src/pages/basics/actions.md           \
src/pages/basics/routes.md            \
src/pages/basics/requests.md          \
src/pages/basics/results.md           \
src/pages/basics/failure.md           \
src/pages/html/index.md               \
src/pages/html/templates.md           \
src/pages/html/forms.md               \
src/pages/html/form-templates.md      \
src/pages/json/index.md               \
src/pages/json/values.md              \
src/pages/json/writes.md              \
src/pages/json/reads.md               \
src/pages/json/formats.md             \
src/pages/json/custom1.md             \
src/pages/json/custom2.md             \
src/pages/json/custom3.md             \
src/pages/json/failure.md             \
src/pages/async/index.md              \
src/pages/async/futures.md            \
src/pages/async/executioncontexts.md  \
src/pages/async/actions.md            \
src/pages/async/ws.md                 \
src/pages/async/failure.md            \


TODO:

-s, --standalone
Produce output with an appropriate header and footer (e.g. a standalone HTML, LaTeX, or RTF file, not a fragment). This option is set automatically for pdf, epub, epub3, fb2, docx, and odt output

--highlight-style=STYLE
Specifies the coloring style to be used in highlighted source code. Options are pygments (the default), kate, monochrome, espresso, zenburn, haddock, and tango

--self-contained
Produce a standalone HTML file with no external dependencies, using data: URIs to incorporate the contents of linked scripts, stylesheets, images, and videos. The resulting file should be “self-contained,” in the sense that it needs no external files and no net access to be displayed properly by a browser. This option works only with HTML output formats, including html, html5, html+lhs, html5+lhs, s5, slidy, slideous, dzslides, and revealjs. Scripts, images, and stylesheets at absolute URLs will be downloaded; those at relative URLs will be sought relative to the working directory (if the first source file is local) or relative to the base URL (if the first source file is remote). --self-contained does not work with --mathjax.

-5, --html5
Produce HTML5 instead of HTML4. This option has no effect for writers other than html. (Deprecated: Use the html5 output format instead.)


