#!/bin/bash
export COMPOSE_INTERACTIVE_NO_CLI=0

COUNT=${1-1}
echo "1. build jmeter-base jmeter-base "
docker build -t jmeter-base jmeter-base
echo "2. build "
docker-compose build 
echo "3. start up"
docker-compose up -d 
echo "4. scale"
docker-compose scale master=1 slave=$COUNT
echo "5. get slave ip"
SLAVE_IP=$(docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq) | grep slave | awk -F' ' '{print $2}' | tr '\n' ',' | sed 's/.$//')
echo "6. get wdir"
WDIR=`docker exec master /bin/pwd | tr -d '\r'`
echo "7. create results"
mkdir -p results

for filename in scripts/*.jmx; do
    echo "for loop"
    NAME=$(basename $filename)
    NAME="${NAME%.*}"
    eval "docker cp $filename master:$WDIR/scripts/"
    eval "docker exec -it master /bin/bash -c 'mkdir $NAME && cd $NAME && ../bin/jmeter -n -t ../$filename -R$SLAVE_IP'"
    # eval "docker cp master:$WDIR/$NAME results/"
done
echo "9, stop and delete"
docker-compose stop && docker-compose rm -f
