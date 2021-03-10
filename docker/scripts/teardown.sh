#!/bin/bash

APP_DIR="gukort2"
cd ../../
if [[ "${PWD##*/}" != "${APP_DIR}" ]]; then
   echo "The ../../ directory must be ${APP_DIR}"
   exit
fi
rm Dockerfile
rm entrypoint.sh
rm .dockerignore

