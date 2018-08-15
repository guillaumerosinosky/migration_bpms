#!/bin/bash
cd ansible
START_TIME=`echo $(($(date +%s%N)/1000000))`
ansible-playbook -i "localhost," -e "@scenarios/$1.yml" create_azure_fdw_swarm.yml
END_TIME=`echo $(($(date +%s%N)/1000000))`
ELAPSED_TIME=$(($END_TIME - $START_TIME))
echo "VM creation time : $ELAPSED_TIME"
