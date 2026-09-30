## README (containerprep) 

### I. Introduction

A selection of my custom container preparation scripts, starting with the steps for [Postgres](https://www.postgresql.org/).

### II. About the project directories

#### config

Not in source control.  It should be created and populated automatically by [step1_postgres_setup.sh](step1_postgres_setup.sh)

#### containerfiles

[Containerfile-alpine-postgres-18_6-experimental](containerfiles/Containerfile-alpine-postgres-18_6-experimental)

#### lib

[definitions.sh](lib/definitions.sh)

[postgres_setup_helpers.sh](lib/postgres_setup_helpers.sh)

---

### III. Instructions

#### 1. Setup

First, run the script [step1_postgres_setup.sh](step1_postgres_setup.sh)

After completion, the contents of the [config](config/) directory should appear.

Obs: if you execute the script again, the files will be renamed and new ones generated.

#### 2. Build

[step2_postgres_build.sh](step2_postgres_build.sh) should create a container image based on the [Containerfile](containerfiles/Containerfile-alpine-postgres-18_6-experimental) 

#### 3. Compose up

Finally, you may wish to start it: [step3_postgres_compose_up.sh](step3_postgres_compose_up.sh)

---

##### Marcelo Eduardo Redoschi 

*September 2026*
