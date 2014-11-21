#!/usr/bin/env bash

# --epub-stylesheet ./essential-play/css/print.css                           \
# --template=src/layouts/page.html                                           \
# --toc-depth=4                                                              \

# To change the output type change the suffix.
#  -o essential-play.pdf


pandoc -S                                                                    \
  -o essential-play.pdf                                                     \
  --table-of-contents                                                        \
  --from=markdown+multiline_tables+fenced_code_blocks+fenced_code_attributes \
  --highlight-style tango                                                    \
  pandoc/title.txt                                                           \
  src/pages/index.md                                                         \
  src/pages/basics/index.md                                                  \
  src/pages/basics/actions.md                                                \
  src/pages/basics/routes.md                                                 \
  src/pages/basics/requests.md                                               \
  src/pages/basics/results.md                                                \
  src/pages/basics/failure.md                                                \
  src/pages/html/index.md                                                    \
  src/pages/html/templates.md                                                \
  src/pages/html/forms.md                                                    \
  src/pages/html/form-templates.md                                           \
  src/pages/json/index.md                                                    \
  src/pages/json/values.md                                                   \
  src/pages/json/writes.md                                                   \
  src/pages/json/reads.md                                                    \
  src/pages/json/formats.md                                                  \
  src/pages/json/custom1.md                                                  \
  src/pages/json/custom2.md                                                  \
  src/pages/json/custom3.md                                                  \
  src/pages/json/failure.md                                                  \
  src/pages/async/index.md                                                   \
  src/pages/async/futures.md                                                 \
  src/pages/async/executioncontexts.md                                       \
  src/pages/async/actions.md                                                 \
  src/pages/async/ws.md                                                      \
  src/pages/async/failure.md                                                 \
  src/pages/links.md                                                         \

