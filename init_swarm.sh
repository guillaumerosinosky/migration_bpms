#!/bin/bash
#docker swarm init
#docker swarm join --token SWMTKN-1-2ny8ztcrl5aldehpl7coiaaxg8nx26lmrzle9v0zzp30iqep0i-7rhf4qxamqbriyfvqeookzxyb vm-vmonly-bpms-from1:2377
#docker swarm leave --force

cd ansible
export AZURE_RESOURCE_GROUPS=rg_vmonly
export AZURE_TAGS=bcd_stackId:vmonly
ansible-playbook -i inventory/azure/azure_wrapper.sh -e "@scenarios/migration_azure_vm_vnet_swarm.yml" -e "bcd_stack_id=vmonly" swarm.yml
