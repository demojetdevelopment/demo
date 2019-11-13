#!/bin/bash

DEMO_NETWORK=$(docker network ls --format="{{.Name}}" -f name=demo | grep demo$)

if [[ -z ${DEMO_NETWORK} ]]
then
    # create demo network
    docker network create demo
fi

WINPTY=''
if [[ -n ${WINDIR} ]]
then
   echo "WINDIR is defined"
   WINPTY='winpty '
fi

NAME_PREFIX="$1"

# ensure that old containers are removed
docker-compose -p $NAME_PREFIX stop
docker-compose -p $NAME_PREFIX rm -f

# start application
docker-compose -p $NAME_PREFIX build --pull
docker-compose -p $NAME_PREFIX up -d --force-recreate

# up application
$WINPTY docker-compose -p $NAME_PREFIX $COMPOSE_FILES exec php-fpm sh -c "cd /var/www/service; composer service:install-local"
