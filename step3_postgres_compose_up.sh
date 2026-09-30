#!/bin/bash
# Marcelo Eduardo Redoschi - September 2026
LIB_DIR="$(pwd)/lib"
DEFINITIONS_FILE_NAME="definitions.sh"
DEFINITIONS_FILE_PATH="$LIB_DIR/$DEFINITIONS_FILE_NAME"
# shellcheck source=lib/definitions.sh
source "${DEFINITIONS_FILE_PATH}"

list_running_containers_cmd="docker ps"

COMPOSE_FILE_PATH="compose-postgres-$PG_VERSION.yml"
compose_cmd="docker-compose -f $COMPOSE_FILE_PATH"
compose_up="$compose_cmd up -d"

echo "$compose_up"
eval "$compose_up"
echo " "

$list_running_containers_cmd
echo " "