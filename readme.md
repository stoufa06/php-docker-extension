# Overview
Creates php extension placeholder (skeleton) for extension development using docker build 


# Description
This is an initial description. For now the it creates c php skeleton for php 8.2.22 using debian 12 OS image. 

Based on dockerfile, it creates a multi-stage docker build stages as fallows :
- `essential` : based on **debian:12** image, installs required packages
- `php-clone` : based on **essential**, clones php repository git target branch with php requested version
- `php-build` : based on **php-clone**, builds php
- `ext-copy` : based on **php-build**, copy c php extension code from SOURCE_FOLDER 
- `ext-create` : based on **php-build**, c php extension code skeleton 
- `ext-build` : based on **ext-create** or ext-copy, builds the extension
- `ext-test` :  based on **ext-build**, tests the extension
- `final` : based on **ext-test**, copy the extension code to SOURCE_FOLDER
# Requirements
- Docker
- Bash

# Usage
```bash
./build.sh
```
## Arguments
Possible Arguments : 

- `PHPVERSION=8.2.22` : set you php version. supports 7+. Default : 8.2.22
- `ACTION=create` : create php extension skeleton on build. Default : create
- `ACTION=copy` : copy php extension source folder from `SOURCE_FOLDER` during build. Default : create
- `EXTENSION_NAME=test` : extension name. Default : test
- `SOURCE_FOLDER=src` : source folder of extension to output/input. Default : src
- `--[docker-build-argument-name]` : any docker build argument like `--no-cache` or `--no-cache-filter ext-build`

Example : 
```bash
./build.sh PHPVERSION=8.3.10 --no-cache-filter ext-build
```