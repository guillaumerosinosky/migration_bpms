# migration_bpms

BPM engines live migration effects on performance evaluation.

## How does this work ?
The steps is to instantiate an infrastructure, deploy BPM solutions on it, and evaluate effects of live migrations by simulating users interaction (processes initialization and human tasks processing) and live migrating the BPMS with a planned scenario. 
After the simulation, various data on processes and task performance are retrieved from the BPMS database and processed.

## Files

Main files :
* cloud-init.ipynb : Jupyter notebook for cloud initialization (VM creation)
* xp.ipynb : Jupyter notebook test platform. Assumes the infrastructure is ready 

Utility scripts :
* create_vm.sh : VM creation
* pull_agents.sh : recover, build, and Docker image creation of BPM agents simulator 
* init_swarm.sh : Docker Swarm cluster initialization, and needed files upload
* deploy.sh : Docker Swarm cluster deployment
* reset_docker.sh : Docker Swarm cluster removal
* migrate.sh / migrate2.sh : migrate the concerned tenant from (respectively to) the origin resource
* come_and_go.sh : Iteratively migrates multiple times from the origin to the resource 

## Libraries usage

These scripts, are based on Docker Swarm, Ansible, Jupyter Notebooks, and Faban.
Uses AgentBPM (https://github.com/Chahrazed-l/AgentBmps.git) for customer simulation, and live migration scripts (soon to be referenced).

## Work in progress 

TODO : add Ansible scripts for infrastructure initialization and retrieval
TODO : add reference for Live Migration scripts (Camunda)


