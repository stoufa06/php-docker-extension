#!/bin/bash
BUILD_ARGS=""
if [ "$#" -gt 0 ]; then
    for ARG in "$@"
    do
    if [[ "$ARG" == '--'* ]]
    then
         BUILD_ARGS="$BUILD_ARGS $ARG"
    else
         BUILD_ARGS="$BUILD_ARGS --build-arg=\"$ARG\""
    fi
       
    done
fi
# echo $BUILD_ARGS
docker build -t soufa06/php-docker-extension:8.2.22 $BUILD_ARGS --output=src --target=final --progress=plain . 2>&1 | tee  build.log 