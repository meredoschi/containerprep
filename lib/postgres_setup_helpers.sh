#!/bin/bash
# Marcelo Eduardo Redoschi - Revised September 2026

# Convenience function - first echo then eval
evaluate () {
  echo "$1"
  eval "$1"
}

# Produces a variable length random password
generate_random_pass () {

  NUM_CHARS=$(( ( RANDOM % 10 )  + 30 )) # variable password length

  random_pass="$(pwgen -s $NUM_CHARS)"

  echo "$random_pass"

}

# (Over)write the text to a file
write_to_file () {

  cmd="echo $1 > $2"
  evaluate "$cmd"

}

# Arguments: 1) SQL_SCRIPT_FILE_PATH, 2) CONTAINER_ENV_FILE_PATH
header_comments() {

  NOW=$(date +"%Y-%m-%d_%H_%M_%S")

  txt1="Postgres databases custom configuration script"
  dashes="----------------------------------------------------------"
  txt2="Author: Marcelo Eduardo Redoschi"
  txt3="Revised: September 2026"
  txt4="Database setup file: $1"
  txt5="Container environment file: $2"
  comments=("$dashes" "$txt1" "$txt2"  "$txt3" "$txt4" "$txt5" "$dashes")

for comment in "${comments[@]}"
do
   echo "/* $comment */"  >> "$1"
done

}

rename_file_to_previous_if_exists () {

NOW="$(date +"%Y-%m-%d_%H_%M_%S")"

  if [ -f "$1" ]; then
      mv -v "$1" "$1.previous-$NOW"
  fi
}

copy_file_to_previous_if_exists () {

NOW="$(date +"%Y-%m-%d_%H_%M_%S")"

  if [ -f "$1" ]; then
      mv -v "$1" "$1.previous-$NOW"
  fi
}

set_variables () {

  random_pass="$(generate_random_pass)"
  db_pass="APP_$1_DB_PASS=\"${random_pass}\""
  db_user="APP_$1_DB_USER=\"$2\""
  db_name="APP_$1_DB_NAME=\"$3\""
  db_host="APP_$1_DB_HOST=\"$4\""
  db_port=$5
  pgpass_file_path=$6
  exports_file_path=$7

  cmds=("$db_user" "$db_name" "$db_pass" "$db_host")

  for cmd in "${cmds[@]}"
  do
     echo "export $cmd"  >> "$exports_file_path"
  done

  build_pg_pass_entry "$4" "$db_port" "$2" "$3" "$random_pass" >> "$pgpass_file_path"

}

build_pg_pass_entry () {

DB_HOST=$1
DB_PORT=$2
DB_USER=$3
DB_NAME=$4
DB_PASS=$5

entry="$DB_HOST:$DB_PORT:$DB_NAME:$DB_USER:$DB_PASS"

echo "$entry"

}

create_roles_and_databases () {

NOW=$(date +"%Y-%m-%d %H:%M:%S")

prod_user="create user $APP_PRODUCTION_DB_USER with encrypted password '${APP_PRODUCTION_DB_PASS}' login createdb;"
dev_user="create user $APP_DEVELOPMENT_DB_USER with encrypted password '${APP_DEVELOPMENT_DB_PASS}' login createdb;"
test_user="create user $APP_TEST_DB_USER with encrypted password '${APP_TEST_DB_PASS}' login createdb;"

dev_db="create database $APP_DEVELOPMENT_DB_NAME with owner $APP_DEVELOPMENT_DB_USER;"
test_db="create database $APP_TEST_DB_NAME with owner $APP_TEST_DB_USER;"
prod_db="create database $APP_PRODUCTION_DB_NAME with owner $APP_PRODUCTION_DB_USER;"
prod_cable_db="create database $APP_PRODUCTION_CABLE_DB_NAME with owner $APP_PRODUCTION_DB_USER;"
prod_cache_db="create database $APP_PRODUCTION_CACHE_DB_NAME with owner $APP_PRODUCTION_DB_USER;"
prod_queue_db="create database $APP_PRODUCTION_QUEUE_DB_NAME with owner $APP_PRODUCTION_DB_USER;"

comment="/* Programmatically generated on $NOW */"

creation_cmds=("$comment" "$prod_user" "$prod_db" "$prod_cable_db" "$prod_cache_db" "$prod_queue_db"
"$test_user" "$test_db" "$dev_user" "$dev_db" )

for cmd in "${creation_cmds[@]}"
do
   echo "$cmd"  >> "$1"
done

}

build_hba_entry () {

kind=$1
db_name=$2
db_user=$3
ip_addr_mask=$4
auth_method=$5

echo "$kind $db_name $db_user $ip_addr_mask $auth_method"

}

build_hba_entries () {

prefix=$1
connection_kind=$2
auth_method=$3
suffix=$4

db_names=("all" "postgres" "postgres" "postgres" "$APP_PRODUCTION_DB_NAME" "$APP_PRODUCTION_CABLE_DB_NAME" "$APP_PRODUCTION_CACHE_DB_NAME"
"$APP_PRODUCTION_QUEUE_DB_NAME" "$APP_TEST_DB_NAME" "$APP_DEVELOPMENT_DB_NAME")

db_users=("postgres" "$APP_TEST_DB_USER" "$APP_DEVELOPMENT_DB_USER" "$APP_PRODUCTION_DB_USER" "$APP_PRODUCTION_DB_USER" "$APP_PRODUCTION_CABLE_DB_USER" "$APP_PRODUCTION_CACHE_DB_USER"
"$APP_PRODUCTION_QUEUE_DB_USER" "$APP_TEST_DB_USER" "$APP_DEVELOPMENT_DB_USER")

allowed_ips=("localhost" "pghost" "127.0.0.1/32" "::1/128" "172.17.0.1/24" "172.22.0.1/24" )

num_databases=${#db_names[@]}
num_users=${#db_users[@]}

if [[ $num_databases != "$num_users" ]]; then
    echo "*** Error!  The number of databases does not match the number of users! ***"
    echo "$num_databases names: ${db_names[*]}"
    echo "$num_users users: ${db_users[*]}"
    echo "Please adjust and try again. End of script."
    exit 2
fi

for allowed_ip in "${allowed_ips[@]}"
do
  db_name="all"
  db_user="postgres"

  indx="0"

  echo " "

  echo "-- $allowed_ip"

  while [ $indx -lt "$num_databases" ]
  do
      res=$(build_hba_entry "$connection_kind ${db_names[$indx]} ${db_users[$indx]} $allowed_ip $auth_method")
      echo "$prefix $res $suffix"
      indx=$((indx+1))
  done

done
}

apply_configuration_and_reload_it () {

  comment="/* Apply the configuration and reload it */"

  # apply_config="copy hba to '/var/lib/postgresql/data/pg_hba.conf';"
  apply_config="copy hba to '/var/lib/postgresql/18/docker/pg_hba.conf';"
  reload_config="select pg_reload_conf();"

  cmds=(" " "$comment" " " "$apply_config" " " "$reload_config")

for cmd in "${cmds[@]}"
do
   echo "$cmd"  >> "$1"
done

}
