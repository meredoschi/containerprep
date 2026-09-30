#!/bin/bash
# Marcelo Eduardo Redoschi - September 2026

# CONFIG_DIR="$(pwd)/config"
LIB_DIR="$(pwd)/lib"

DEFINITIONS_FILE_NAME="definitions.sh"
DEFINITIONS_FILE_PATH="$LIB_DIR/$DEFINITIONS_FILE_NAME"
# shellcheck source=lib/definitions.sh
source "${DEFINITIONS_FILE_PATH}"

CONTAINER_FILES_DIR="containerfiles"
CONTAINER_FILE_NAME="Containerfile-alpine-postgres-$PG_VERSION-$APP_NAME"
CONTAINER_FILE_PATH="$CONTAINER_FILES_DIR/$CONTAINER_FILE_NAME"

#podman_build_cmd="podman build -f $CONTAINER_FILE_PATH -t $CUSTOM_IMAGE_NAME ."
docker_build_cmd="sudo docker build . -f $CONTAINER_FILE_PATH -t $CUSTOM_IMAGE_NAME --no-cache"

build_cmd=$docker_build_cmd

echo "$build_cmd"
eval "$build_cmd"
echo " "