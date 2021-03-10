#!/bin/bash

APP_DIR="gukort2"
cd ../../
if [[ "${PWD##*/}" != "${APP_DIR}" ]]; then
   echo "The ../../ directory must be ${APP_DIR}"
   exit
fi
cp -a Dockerfile    docker/api/
cp -a entrypoint.sh docker/api/
cp -a .dockerignore docker/api/

