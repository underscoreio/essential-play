#!/usr/bin/env bash

# Requires:
#  brew install pandoc
                                                       \
echo "Running Pandoc @ $(date)"

cat running.order | xargs \
 pandoc -S                                                                    \
  -o essential-play.html                                                      \
  -V papersize:a4paper                                                       \
  -V fontfamily:utopia                                                       \
  --table-of-contents                                                        \
  --from=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block \
  --highlight-style tango                                                    \
  --standalone                                                               \
  --self-contained                                                           \
  pandoc/metadata.yaml
