#!/bin/bash


# Get the username and user ID
COMPOSE_BAKE=true USERNAME=$(id -un) USER_UID=$(id -u) USER_GID=$(id -g) GROUPNAME=$(id -gnr) docker compose $@
