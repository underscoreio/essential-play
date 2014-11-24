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

# Notes:
# For xelatex set values for: mainfont, sansfont, monofont, mathfont

# Templates are something we'll probably want to use:
# http://johnmacfarlane.net/pandoc/demo/example9/templates.html

# Input formats we use:
FORMATS=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block

cat running.order | xargs        \
 pandoc -S                       \
  -o essential-play.pdf          \
  -V papersize:a4paper           \
  --latex-engine=xelatex         \
  -V mainfont:'[Color=primary, Path=fonts/Lato2OFL/,BoldItalicFont=Lato-BlackItalic,BoldFont=Lato-Bold,ItalicFont=Lato-Italic]{Lato-Regular}'   \
  -V monofont:'Menlo'            \
  -V fontsize:11pt               \
  -V lof:true                    \
  -V lot:true                    \
  --chapters                     \
  --number-sections              \
  --table-of-contents            \
  --toc-depth=5                  \
  --from=$FORMATS                \
  --highlight-style tango        \
  --template=pandoc/template.tex \
  --standalone                   \
  --self-contained               \
  pandoc/metadata.yaml


