#!/usr/bin/env bash
# -*- coding: utf-8 -*-

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
filename="/sdcard/$timestamp.mp4"

function finish {
  sleep 1
  echo "\nPulling file..."
  adb pull $filename
  adb shell rm $filename

  echo "Making gif!"
  ffmpeg -y -i "$timestamp.mp4" -vf "fps=30,scale=640:-1:flags=lanczos,palettegen" palette.png
  ffmpeg -i "$timestamp.mp4" -i palette.png -filter_complex "fps=30,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse" "$timestamp.gif"

  rm palette.png
  rm "$timestamp.mp4"
  echo "Done!"
}

trap finish EXIT

echo "Recording $filename... Press Ctrl + C to end the recording"
adb shell screenrecord $filename


