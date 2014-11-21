#!/usr/bin/env bash

# Requires:
#  brew install pandoc

# Jono's noodling notes:
# --epub-stylesheet ./essential-play/css/print.css                           \
# --template=src/layouts/page.html                                           \
# --toc-depth=4                                                              \

# To change the output type change the suffix.
#  -o essential-play.pdf

echo "Running Pandoc @ $(date)"

# NB: We prefer
#   --latex-engine=xelatex                                                     \
#...but this does not support the fontfamily value.
# For xelatex set values for: mainfont, sansfont, monofont, mathfont

cat running.order | xargs \
 pandoc -S                                                                   \
  -o essential-play.pdf                                                      \
  -V papersize:a4paper                                                       \
  -V fontfamily:fouriernc                                                    \
  -V fontsize:11pt                                                           \
  --chapters                                                                 \
  --table-of-contents                                                        \
  --toc-depth=5                                                              \
  --from=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block \
  --highlight-style tango                                                    \
  --standalone                                                               \
  --self-contained                                                           \
  pandoc/metadata.yaml
