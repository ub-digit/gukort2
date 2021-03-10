#!/bin/bash

APP_DIR="gukort2"
cd ../../
if [[ "${PWD##*/}" != "${APP_DIR}" ]]; then
   echo "The ../../ directory must be ${APP_DIR}"
   exit
fi
cp -a docker/api/Dockerfile    .
cp -a docker/api/entrypoint.sh .
cp -a docker/api/.dockerignore .

