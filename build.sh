#!/bin/bash 
docker build -t soufa06/php-docker-extension:8.2.22 --output=src --target=final --progress=plain --no-cache-filter ext-test . 2>&1 | tee  build.log 