#!/usr/bin/env bash
# -*- coding: utf-8 -*-

workdir=$(pwd)
tmpdir=$(mktemp -d)
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

margin=50
text_margin=25
offset_x="$margin"
screenshots=()

i="0"

function finish {
  convert -size $(printf '%sx1280' "$offset_x") xc:white -gravity NorthWest \
          "${screenshots[@]}" "$timestamp.png"

  popd
  
  mv "$tmpdir/$timestamp.png" .
  rm -rf "$tmpdir"
}

trap finish EXIT

pushd "$tmpdir"

while true
do

  if [ -z $1 ]; then
    devices=($(adb devices | sed -rn 's/^(.+)\sdevice$/\1 /p'))
    echo "Available devices:"
    for d in "${!devices[@]}"; do
      echo "$d. ${devices[$d]}"
    done
    printf "Select device by number: "
    read selected
    device="${devices[selected]}"
    if [ -z $device ]; then
        echo "Could not find a device"
        exit 1
    fi
  else
      device=$1
  fi

  printf "\nPress Ctrl+C when you are done capturing screenshots.\n"
  printf "Optional caption [Enter]: "
          
  read caption

  filename="$timestamp--$i.png"
  remote_filename="/sdcard/$filename"

  adb -s $device shell screencap -p $remote_filename

  sleep 1
  adb -s $device pull $remote_filename
  adb -s $device shell rm $remote_filename

  convert $filename -resize 720x1080 \
          -gravity south -splice 0x200 $filename
          
  convert $filename -gravity north \
          -font Roboto-Thin -pointsize 28 -fill black \
          -annotate +0+$[1080+$text_margin] "$caption" $filename 
          
  screenshots+=("-draw" "image over $offset_x,100 0,0 '$filename'")
  image_width=$(convert "$filename" -print "%w" /dev/null)
  offset_x=$[$margin+$offset_x+$image_width]
    
  i=$[$i+1]
  
done
