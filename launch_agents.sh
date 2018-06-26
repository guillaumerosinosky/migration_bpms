#!/bin/bash

if [[ ! -z "$2" ]]
then
  NAME=$2
else
  NAME=bpmsagent
fi
docker rm -f $NAME
docker run --name $NAME -d -e BPMSNAME='bonita' -e URL="$1" -v ${PWD}/config.txt:/tmp/config.txt -e CONFIGFILE='/tmp/config.txt' bpmsagent
