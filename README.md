# migration_bpms

BPM engines live migrations effects on performance benchmarking tool.

## How does this work ?
The steps is to instantiate an infrastructure (if necessary), deploy BPM solutions on it, and evaluate effects of live migrations by simulating users interaction (processes initialization and human tasks processing) and live migrating the BPMS with a planned scenario. 
After the simulation, various data on processes and task performance are retrieved from the BPMS database and processed.

## What are these files ? How do I begin ?

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

## What can we do with it ?

See coopis2018/xp_paper.ipynb file for the results obtained a modified version of Bonita 7.3.2 Performance edition. 


## What do I need to make this work ?

These scripts, are based on Docker Swarm, Ansible, Jupyter Notebooks, and Faban. You should have all these tools installed. 
Uses AgentBPM (https://github.com/Chahrazed-l/AgentBPMS) for customer simulation, and live migration scripts (soon to be referenced).

In the current state of this repository, there is still a few files to be added (Ansible scripts and Live Migration containers are not yet ready to be shared). We are working on it.



