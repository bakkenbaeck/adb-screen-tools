#!/usr/bin/env bash
# -*- coding: utf-8 -*-

if ! command -v adb > /dev/null; then
    echo "Missing adb";
    exit 1
fi
if ! command -v ffmpeg  > /dev/null; then
    echo "Missing ffmpeg";
    exit 1
fi

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
filename="/sdcard/$timestamp.mp4"
if [ -z $1 ]; then
    device=$(adb devices | grep '^.\+\sdevice$' | head -1 | cut -f 1)
    if [ -z $device ]; then
        echo "Could not find a device"
        exit 1
    fi
else
    device=$1
fi

function finish {
  sleep 1
  echo "\nPulling file..."
  adb -s $device pull $filename
  adb -s $device shell rm $filename

  echo "Making gif!"
  ffmpeg -y -i "$timestamp.mp4" -vf "fps=30,scale=640:-1:flags=lanczos,palettegen" palette.png
  ffmpeg -i "$timestamp.mp4" -i palette.png -filter_complex "fps=30,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse" "$timestamp.gif"

  rm palette.png
  rm "$timestamp.mp4"
  echo "Done!"
}

trap finish EXIT

echo "Recording $filename... Press Ctrl + C to end the recording"
adb -s $device shell screenrecord $filename
