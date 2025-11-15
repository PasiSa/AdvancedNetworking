#!/bin/bash

# Usage: drawio-export diagram.drawio
# Produces: diagram.svg

INPUT="$1"
BASENAME="${INPUT%.drawio}"
OUTPUT="${BASENAME}.svg"

/Applications/draw.io.app/Contents/MacOS/draw.io \
    -x \
    -f svg \
    -o "$OUTPUT" \
    "$INPUT"
