#!/usr/bin/env bash
# -*- coding: utf-8 -*-

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_ESC=255}

workdir=$(pwd)
tmpdir=$(mktemp -d)
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

margin=50
text_margin=25
offset_x="$margin"
screenshots=()

i="0"
devices=($(adb devices | grep '^.\+\sdevice$' | head -1 | cut -f 1))
for d in "${!devices[@]}"; do
  options+=("$d" "${devices[$d]}")
done

function finish {
  if [ $i -gt 0 ]; then
    convert -size $(printf '%sx1280' "$offset_x") xc:white -gravity NorthWest \
            "${screenshots[@]}" "$timestamp.png"

    popd
    
    mv "$tmpdir/$timestamp.png" .
    rm -rf "$tmpdir"
  fi
}

trap "finish" SIGHUP SIGINT SIGTERM

pushd "$tmpdir"

while true
do

  if [ -z $1 ]; then
  
    tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/selected-device$$
    trap "rm -f $tempfile" 0 1 2 5 15

    dialog --backtitle "adb-screen-capture" \
              --title "Select source" \
              --cancel-label "Done" \
              --ok-label "Select" \
              --menu "Available devices" \
              12 "$(($(tput cols)/2))" "${#options[@]}" \
              "${options[@]}" 2> $tempfile
                        
    case $? in
      $DIALOG_OK)
        selected=`cat $tempfile`
        device="${devices[selected]}";;
      $DIALOG_CANCEL)
        finish
        exit 0;;
      $DIALOG_ESC)
        exit 1;;
    esac
    
    if [ -z $device ]; then
        echo "Could not find a device"
        exit 1
    fi
  else
      device=$1
  fi

  tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/caption$$
  trap "rm -f $tempfile" 0 1 2 5 15

  dialog --backtitle "adb-screen-capture" \
          --title "Screenshot Caption" \
          --cancel-label "Skip" \
          --ok-label "Save" \
          --inputbox "Enter caption" \
          12 "$(($(tput cols)/2))" 2> $tempfile
         
  case $? in
    $DIALOG_OK)
      caption=`cat $tempfile`;;
    $DIALOG_CANCEL)
      caption="";;
    $DIALOG_ESC)
      exit 1;;
  esac
     
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
