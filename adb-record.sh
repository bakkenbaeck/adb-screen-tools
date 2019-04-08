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
  echo "Pulling file..."
  adb -s $device pull $filename
  adb -s $device shell rm $filename

  echo "Converting to webm..."
  ffmpeg -loglevel panic -i "$timestamp.mp4" "$timestamp.webm"
}

trap finish SIGINT

printf "Recording $filename...\nPress Ctrl + C to end the recording\n"
adb -s $device shell screenrecord $filename
