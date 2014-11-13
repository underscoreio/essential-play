Pandoc Notes

Right so, this is okay as a starting point:

pandoc -S -o essential-play.html      \
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
--epub-stylesheet ./essential-play/css/print.css

pandoc -S -o essential-play.epub      \
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
--epub-stylesheet ./essential-play/css/print.css

pandoc -S -o essential-play.pdf       \
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
--epub-stylesheet ./essential-play/css/print.css


cruft
=======

Quick and dirty

  - unordered,
  - no page breaks,
  - no images,
  - styles ???

pandoc -S -o essential-play.epub      \
             pandoc/title.txt         \
             `find src/pages  -name '*.md'` \
             --epub-stylesheet ./essential-play/css/print.css


Bugger

  - formatting goes to tits up

pandoc -S -o essential-play.epub  pandoc/title.txt  src/pages/index.md pandoc/pagebreak.html src/pages/basics/index.md pandoc/pagebreak.html src/pages/basics/actions.md pandoc/pagebreak.html src/pages/basics/routes.md pandoc/pagebreak.html src/pages/basics/requests.md pandoc/pagebreak.html src/pages/basics/results.md pandoc/pagebreak.html src/pages/basics/failure.md pandoc/pagebreak.html src/pages/html/index.md pandoc/pagebreak.html src/pages/html/templates.md pandoc/pagebreak.html src/pages/html/forms.md pandoc/pagebreak.html src/pages/html/form-templates.md pandoc/pagebreak.html src/pages/json/index.md pandoc/pagebreak.html src/pages/json/values.md pandoc/pagebreak.html src/pages/json/writes.md pandoc/pagebreak.html src/pages/json/reads.md pandoc/pagebreak.html src/pages/json/formats.md pandoc/pagebreak.html src/pages/json/custom1.md pandoc/pagebreak.html src/pages/json/custom2.md pandoc/pagebreak.html src/pages/json/custom3.md pandoc/pagebreak.html src/pages/json/failure.md pandoc/pagebreak.html src/pages/async/index.md pandoc/pagebreak.html src/pages/async/futures.md pandoc/pagebreak.html src/pages/async/executioncontexts.md pandoc/pagebreak.html pandoc/pagebreak.html src/pages/async/actions.md pandoc/pagebreak.html src/pages/async/ws.md pandoc/pagebreak.html src/pages/async/failure.md     --epub-stylesheet ./essential-play/css/print.css


Hmmmm

pandoc -S -o essential-play.epub  pandoc/title.txt  src/pages/index.md pandoc/pagebreak.tex src/pages/basics/index.md pandoc/pagebreak.tex src/pages/basics/actions.md pandoc/pagebreak.tex src/pages/basics/routes.md pandoc/pagebreak.tex src/pages/basics/requests.md pandoc/pagebreak.tex src/pages/basics/results.md pandoc/pagebreak.tex src/pages/basics/failure.md pandoc/pagebreak.tex src/pages/html/index.md pandoc/pagebreak.tex src/pages/html/templates.md pandoc/pagebreak.tex src/pages/html/forms.md pandoc/pagebreak.tex src/pages/html/form-templates.md pandoc/pagebreak.tex src/pages/json/index.md pandoc/pagebreak.tex src/pages/json/values.md pandoc/pagebreak.tex src/pages/json/writes.md pandoc/pagebreak.tex src/pages/json/reads.md pandoc/pagebreak.tex src/pages/json/formats.md pandoc/pagebreak.tex src/pages/json/custom1.md pandoc/pagebreak.tex src/pages/json/custom2.md pandoc/pagebreak.tex src/pages/json/custom3.md pandoc/pagebreak.tex src/pages/json/failure.md pandoc/pagebreak.tex src/pages/async/index.md pandoc/pagebreak.tex src/pages/async/futures.md pandoc/pagebreak.tex src/pages/async/executioncontexts.md pandoc/pagebreak.tex pandoc/pagebreak.tex src/pages/async/actions.md pandoc/pagebreak.tex src/pages/async/ws.md pandoc/pagebreak.tex src/pages/async/failure.md


How about

pandoc -S -o essential-play.epub  pandoc/title.txt  src/pages/index.md src/pages/basics/index.md src/pages/basics/actions.md src/pages/basics/routes.md src/pages/basics/requests.md src/pages/basics/results.md src/pages/basics/failure.md src/pages/html/index.md src/pages/html/templates.md src/pages/html/forms.md src/pages/html/form-templates.md src/pages/json/index.md src/pages/json/values.md src/pages/json/writes.md src/pages/json/reads.md src/pages/json/formats.md src/pages/json/custom1.md src/pages/json/custom2.md src/pages/json/custom3.md src/pages/json/failure.md src/pages/async/index.md src/pages/async/futures.md src/pages/async/executioncontexts.md pandoc/pagebreak.tex src/pages/async/actions.md src/pages/async/ws.md src/pages/async/failure.md

