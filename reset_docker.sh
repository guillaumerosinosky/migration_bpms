#!/bin/bash
docker stack rm $(docker stack ls --format {{.Name}}) 
