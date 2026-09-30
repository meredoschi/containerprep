#!/bin/bash
# Marcelo Eduardo Redoschi - September 2026
LIB_DIR="$(pwd)/lib"
DEFINITIONS_FILE_NAME="definitions.sh"
DEFINITIONS_FILE_PATH="$LIB_DIR/$DEFINITIONS_FILE_NAME"
# shellcheck source=lib/definitions.sh

source "${DEFINITIONS_FILE_PATH}"

COMPOSE_FILE_PATH="compose-postgres-$PG_VERSION.yml"

COMPOSE_FILE_PATH="compose-postgres-$PG_VERSION.yml"
compose_cmd="docker-compose -f $COMPOSE_FILE_PATH"

compose_stop="$compose_cmd stop"
echo "$compose_stop"
eval "$compose_stop"

compose_down="$compose_cmd down"
echo "$compose_down"
eval "$compose_down"