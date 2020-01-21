#!/usr/bin/env bash
# -*- coding: utf-8 -*-

margin=50
text_margin=25
offset_x="$margin"
screenshots=()

font="roboto-thin.ttf"
if [ ! -f "$font" ]; then
  echo "Download roboto-thin from google..."
  curl https://fonts.gstatic.com/s/roboto/v20/KFOkCnqEu92Fr1MmgVxIIzc.ttf \
          --output "$font"
fi

i="0"
tmpdir=$(mktemp -d)
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

for original in "$@"; do
  echo "Resizing $original"

  caption="$i"
  filename="$tmpdir/$i.png"
  cp "$original" "$filename"
  convert "$filename" -resize 720x1080 \
          -gravity south -splice 0x200 "$filename"
  
  convert "$filename" -gravity north \
          -font "$font" -pointsize 28 -fill black \
          -annotate +0+$[1080+$text_margin] "$caption" "$filename"
  screenshots+=("-draw" "image over $offset_x,100 0,0 '$filename'")
  image_width=$(convert "$filename" -print "%w" /dev/null)
  offset_x=$[$margin+$offset_x+$image_width]
    
  i=$[$i+1]
done

echo "Merging..."
convert -size $(printf '%sx1280' "$offset_x") xc:white -gravity NorthWest \
            "${screenshots[@]}" "$timestamp.png"

echo "Created $timestamp.png"