cd ~/git/AgentBPMS
git pull
mvn clean install
docker build -t bpmsagent .
docker save bpmsagent |gzip >/home/ubuntu/scripts_gr/ansible/files/docker/bpmsagent.tar.gz
