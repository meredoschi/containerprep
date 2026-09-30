#!/bin/bash
# Marcelo Eduardo Redoschi - Updated 22 09 2026

CONFIG_DIR="$(pwd)/config"
LIB_DIR="$(pwd)/lib"

DEFINITIONS_FILE_NAME="definitions.sh"
DEFINITIONS_FILE_PATH="$LIB_DIR/$DEFINITIONS_FILE_NAME"
# shellcheck source=lib/definitions.sh
source "${DEFINITIONS_FILE_PATH}"

SETUP_HELPERS_FILE_NAME="postgres_setup_helpers.sh"
SETUP_HELPERS_FILE_PATH="$LIB_DIR/$SETUP_HELPERS_FILE_NAME"
# shellcheck source=lib/postgres_setup_helpers.sh
source "${SETUP_HELPERS_FILE_PATH}"

EXPORTS_FILE_NAME="postgres-$PG_VERSION-container-exports.sh"
EXP_PATH="$CONFIG_DIR/$EXPORTS_FILE_NAME"
PG_ENV_FILE_NAME="postgres-$PG_VERSION-container.env"
PG_ENV_FILE_PATH="$CONFIG_DIR/$PG_ENV_FILE_NAME"
PG_PASS_FILE_NAME="postgres-$PG_VERSION-container-pgpass"
PG_PASS_PATH="$CONFIG_DIR/$PG_PASS_FILE_NAME"
SQL_SCRIPT_FILE="postgres-$PG_VERSION-container-config.sql"
SQL_SCRIPT_FILE_PATH="$CONFIG_DIR/$SQL_SCRIPT_FILE"
CONTAINER_ENV_FILE="$APP_NAME-postgres-$PG_VERSION.env"
CONTAINER_ENV_FILE_PATH="$CONFIG_DIR/$CONTAINER_ENV_FILE"

# Flow

mkdir -pv "$CONFIG_DIR"

PG_PASS=$(generate_random_pass)

files_to_rename=("$EXP_PATH" "$PG_ENV_FILE_PATH" "$PG_PASS_PATH" "$SQL_SCRIPT_FILE_PATH")

for current_path in "${files_to_rename[@]}"

do
  rename_file_to_previous_if_exists "$current_path"
done


row1="POSTGRES_PASSWORD=$PG_PASS"
echo "$row1" >> "$PG_ENV_FILE_PATH"

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="*"

pg_pass_entry=$(build_pg_pass_entry "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME" "$PG_PASS")

# First entry
echo "$pg_pass_entry" > "$PG_PASS_PATH"

prod_role="${APP_NAME}1"
test_role="${APP_NAME}2"
dev_role="${APP_NAME}3"

prod_db="$APP_NAME""_production"

# Ruby on Rails specific
prod_cable_db="$prod_db""_cable"
prod_cache_db="$prod_db""_cache"
prod_queue_db="$prod_db""_queue"

prod_db="$APP_NAME""_production"
prod_db="$APP_NAME""_production"

test_db="$APP_NAME""_test"
dev_db="$APP_NAME""_development"

               # Environment       # DB user      # DB name         # Host       # Port     # PGPASS         # EXPORTS
set_variables  "PRODUCTION"        "$prod_role"  "$prod_db"         "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"
set_variables  "PRODUCTION_CACHE"  "$prod_role"  "$prod_cache_db"   "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"
set_variables  "PRODUCTION_CABLE"  "$prod_role"  "$prod_cable_db"   "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"
set_variables  "PRODUCTION_QUEUE"  "$prod_role"  "$prod_queue_db"   "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"
set_variables  "TEST"              "$test_role"  "$test_db"         "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"
set_variables  "DEVELOPMENT"       "$dev_role"   "$dev_db"          "$DB_HOST"  "$PG_PORT" "$PG_PASS_PATH"  "$EXP_PATH"

cmd2="source $EXP_PATH"
eval "$cmd2"

cmd="chmod 0600 $PG_PASS_PATH"
eval  "$cmd"

header_comments "$SQL_SCRIPT_FILE_PATH" "$CONTAINER_ENV_FILE_PATH"

create_roles_and_databases "$SQL_SCRIPT_FILE_PATH"

create_hba_table_cmd="create table if not exists hba ( lines text );"

echo "$create_hba_table_cmd" >> "$SQL_SCRIPT_FILE_PATH"

prefix="insert into hba (lines) values ('"
suffix="');"
build_hba_entries "$prefix" "host" "scram-sha-256" "$suffix" >> "$SQL_SCRIPT_FILE_PATH"

apply_configuration_and_reload_it "$SQL_SCRIPT_FILE_PATH"
cmd="ls $CONFIG_DIR"
eval "$cmd"
echo " "