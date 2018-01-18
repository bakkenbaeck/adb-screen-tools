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
    export ANDROID_SERIAL=$(adb devices | grep '^.\+\sdevice$' | head -1 | cut -f 1)
    if [ -z $ANDROID_SERIAL ]; then
        echo "Could not find a device"
        exit 1
    fi
else
    export ANDROID_SERIAL=$1
fi

function finish {
  sleep 1
  echo "Pulling file..."
  adb pull $filename
  adb shell rm $filename

  echo "Making gif!"
  ffmpeg -y -i "$timestamp.mp4" -vf "fps=30,scale=640:-1:flags=lanczos,palettegen" palette.png
  ffmpeg -i "$timestamp.mp4" -i palette.png -filter_complex "fps=30,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse" "$timestamp.gif"

  rm palette.png
  rm "$timestamp.mp4"
  echo "Done!"
}

trap finish SIGINT

printf "Recording $filename...\nPress Ctrl + C to end the recording\n"
adb shell screenrecord $filename
