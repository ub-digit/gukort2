#!/bin/bash

IMAGE_API=`grep IMAGE_API ../.env | cut -d = -f 2`
AFFIRMATIVE="yes"
cd ../../
echo "Do you want to build the \"${IMAGE_API}\" image ("${AFFIRMATIVE}"/no)? " | tr -d '\n'
read answer
if [[ $answer = "${AFFIRMATIVE}" ]]; then
  echo "Building ${IMAGE_API} ..."
  docker build -t ${IMAGE_API} .
else
  echo "No build executed."
fi

