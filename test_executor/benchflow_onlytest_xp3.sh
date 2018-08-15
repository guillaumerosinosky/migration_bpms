#!/bin/bash
#
# Prerequisites:
# 
# wget, curl, jq, sed: 
#		Ubuntu:
# 		$ sudo apt-get update

# 		$ sudo apt-get install wget curl jq awk

#		OSX:
# 		$ brew update

# 		$ brew install wget curl jq awk

#
# set -ex
set -e
#set -x #echo on
#-----Configuration details-----#
PROPERTY_FILE=config.properties
#-----Configuration details-----#

#-----Set the correct tools if we are on OSX-----#
# DESCRIPTION OF PROBLEM: Implementations of sed, readlink, zcat, etc. are different on OS X and Linux.
# SOURCE: https://gist.github.com/bittner/5436f3dc011d43ab7551

# cross-OS compatibility (greadlink, gsed, zcat are GNU implementations for OS X)
[[ `uname` == 'Darwin' ]] && {
  which greadlink gsed gzcat > /dev/null && {
    export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
  } || {
    echo 'ERROR: GNU utils required for Mac. You may use homebrew to install them: brew install coreutils gnu-sed'
    exit 1
  }
}
#-----Set the correct tools if we are on OSX-----#

#-----Helper function----#

function resolve_path()
{
  local resolved=$(eval "readlink -f "$1"")
  if [[ -e "$resolved" ]]
  then
    echo "$resolved"  
  else
    echo "$1"
  fi
}  

function getProperty() {
   PROP_KEY=$1
   PROP_VALUE=`cat $PROPERTY_FILE | grep "$PROP_KEY" | cut -d'=' -f2`
   echo $PROP_VALUE
}

#-----Helper function----#

#-----Get commands and arguments-----#

RESOLVEDARGS=()
for var in "$@"
do
  resolved=$(resolve_path "$var")
  len=${#RESOLVEDARGS[@]}
  RESOLVEDARGS["$len"]="$resolved"
done

#-----Get commands and arguments-----#

#-----Business Logic functions----#
function deploy_faban()
{
  JAVA_HOME_FABAN=$(getProperty "java.home")

}


function generate_test()
{
  IFS='|'
  # Configure the Faban driver
  FABAN_IP=$(getProperty "faban.ip")
  JAVA_HOME_FABAN=$(getProperty "java.home")

  # Set configurations
  NUM_USERS=$1
  BPM_FILE=$2
  RAMPUP=$3
  STEADYSTATE=$4
  RAMPDOWN=$5
  TENANT_NAME=$6
  if [[ ! -z "$7" ]]
  then
    PROPERTY_FILE=$7
    echo "Property file : $PROPERTY_FILE"
  fi
  if [[ ! -z "$8" ]]
  then
    TEST_NAME=$8
    echo "Test name : $TEST_NAME"
  fi
  if [[ ! -z "$9" ]]
  then
    FABAN_IP=$9
    echo "Faban ip : $FABAN_IP"
  fi
  if [[ ! -z "${10}" ]]
  then
    BPM_AGENT_IP=${10}
    echo "BPM agent ip : $BPM_AGENT_IP"
  fi

  #if [[ ! -z "$8" ]]
  #then
  #  AGENTS=$8
  #  echo $AGENTS
  #else
  #  AGENTS=$NUM_USERS
  #fi
  #if [[ ! -z "$9" ]]
  #then
  #  FABAN_IPS=$9
  #  echo $FABAN_IPS
  #else
  #  FABAN_IPS=$FABAN_IP
  #fi
  # Get a new test id
  TEST_ID="${TEST_NAME}_${TENANT_NAME}_$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"

  echo "The generated test ID is $TEST_ID"

  # Configure the template for this test in the tmp folder
  rm -rf ./drivers/tmp/*

  FABAN_PORT=9980 #tmp

  # Faban deployment
  cp -aR ./templates/deployment_descriptor/template/* ./drivers/tmp/
  sed -i.bak 's/${TENANT_NAME}/'$TENANT_NAME'/' ./drivers/tmp/faban-docker-compose-harness.yml 
  sed -i.bak 's/${FABAN_PORT}/'$FABAN_PORT'/' ./drivers/tmp/faban-docker-compose-harness.yml 
  sed -i.bak 's/${FABAN_IP}/'$FABAN_IP'/' ./drivers/tmp/faban-docker-compose-harness.yml 
  
  #sed -i.bak 's/${TENANT_NAME}/'$TENANT_NAME'/' ./drivers/tmp/faban-docker-compose-agent.yml 

  echo "Deploying Faban harness"
  docker stack deploy --compose-file="./drivers/tmp/faban-docker-compose-harness.yml" $TEST_NAME

  #echo "Deploying Faban agent"
  #docker stack deploy --compose-file="./drivers/tmp/faban-docker-compose-agent.yml" $TEST_NAME


  sleep 10
  echo "Get harness IP"
  IFS='  '
  TMP=($(docker service inspect $(docker service ls --filter name="${TEST_NAME}_faban-harness_${TENANT_NAME}" --format '{{.ID}}') --format '{{range $value := .Endpoint.VirtualIPs}} {{$value.Addr}} {{end}}'))
  
  echo $TMP
  TMP2=(${TMP[0]})
  IFS="/"
  echo $TMP2
  HARNESS_IP=(${TMP2[0]})
  echo "Harness IP : $HARNESS_IP"

  echo "Get agent IP"
  IFS='  '
  TMP=$(docker service inspect $(docker service ls --filter name="${TEST_NAME}_faban-agent_${TENANT_NAME}" --format '{{.ID}}') --format '{{range $value := .Endpoint.VirtualIPs}} {{$value.Addr}} {{end}}')
  echo $TMP
  TMP=${TMP[0]}
  IFS="/"
  AGENT_IP=(${TMP[0]})
  echo "Agent IP : $AGENT_IP"
  IFS="|"


  AGENTS="$AGENT_IP:$NUM_USERS"
  FABAN_IPS="${HARNESS_IP} $AGENT_IP"
  FABAN_IP=$HARNESS_IP
  #AGENTS="$NUM_USERS"
  #FABAN_IPS="${HARNESS_IP}"
  cp -aR ./templates/faban/driver/bonita_faban_onlytest/* ./drivers/tmp/

  sed -i.bak 's/${FABAN_IP}/'$FABAN_IP'/' ./drivers/tmp/build.properties
  sed -i.bak 's/${TEST_NAME}/'$TEST_ID'/' ./drivers/tmp/build.properties
  sed -i.bak 's/${JAVA_HOME_FABAN}/'$JAVA_HOME_FABAN'/' ./drivers/tmp/build.xml
  rm ./drivers/tmp/build.properties.bak
  rm ./drivers/tmp/build.xml.bak

  # Deploy
  sed -i.bak 's/${TEST_NAME}/'$TEST_ID'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${FABAN_IPS}/'${FABAN_IPS}'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${JAVA_HOME_FABAN}/'$JAVA_HOME_FABAN'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${NUM_USERS}/'$NUM_USERS'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${AGENTS}/'$AGENTS'/' ./drivers/tmp/deploy/run.xml
  FABAN_OUTPUT_DIR=$(getProperty "faban.output.dir")
  sed -i.bak 's/${FABAN_OUTPUT_DIR}/'$FABAN_OUTPUT_DIR'/' ./drivers/tmp/deploy/run.xml
  SUT_IP=$(getProperty "sut.ip")
  sed -i.bak 's/${SUT_IP}/'$SUT_IP'/' ./drivers/tmp/deploy/run.xml
  SUT_PORT=$(getProperty "sut.port")
  sed -i.bak 's/${SUT_PORT}/'$SUT_PORT'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${BPM_FILE}/'$BPM_FILE'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${RAMPUP}/'$RAMPUP'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${STEADYSTATE}/'$STEADYSTATE'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${RAMPDOWN}/'$RAMPDOWN'/' ./drivers/tmp/deploy/run.xml
  sed -i.bak 's/${TENANT_NAME}/'$TENANT_NAME'/' ./drivers/tmp/deploy/run.xml
  # Config (just replace with the one generated for deploy)
  yes | cp -rf ./drivers/tmp/deploy/run.xml ./drivers/tmp/config/run.xml

  rm ./drivers/tmp/deploy/run.xml.bak
#src/com/testnscale/corehttp
  sed -i.bak 's/${TEST_NAME}/'$TEST_ID'/' ./drivers/tmp/src/com/testnscale/corehttp/BonitaRestDriver.java

  rm ./drivers/tmp/src/com/testnscale/corehttp/BonitaRestDriver.java.bak

  # Configure the deployment descriptor
  SUT_HOSTNAME=$(getProperty "sut.hostname")
  cp -aR ./templates/deployment_descriptor/template/docker-compose.yml ./drivers/tmp/deploy
  sed -i.bak 's/${SUT_HOSTNAME}/'$SUT_HOSTNAME'/' ./drivers/tmp/deploy/docker-compose.yml

  cp -aR ./templates/deployment_descriptor/template/bpm-docker-compose-agent.yml ./drivers/tmp
  sed -i.bak 's/${TENANT_NAME}/'$TENANT_NAME'/' ./drivers/tmp/bpm-docker-compose-agent.yml 
  sed -i.bak 's/${TENANT_NAME}/'$TENANT_NAME'/' ./drivers/tmp/bpm-docker-compose-agent.yml 
  sed -i.bak 's/${BPM_AGENT_IP}/'$BPM_AGENT_IP'/' ./drivers/tmp/bpm-docker-compose-agent.yml 
  #sed -i.bak 's/${CARTS_REPLICAS}/'$CARTS_REPLICAS'/' ./drivers/tmp/deploy/docker-compose.yml
  #sed -i.bak 's/${CARTS_CPUS_LIMITS}/'$CARTS_CPUS_LIMITS'/' ./drivers/tmp/deploy/docker-compose.yml
  #sed -i.bak 's/${CARTS_CPUS_RESERVATIONS}/'$CARTS_CPUS_RESERVATIONS'/' ./drivers/tmp/deploy/docker-compose.yml
  #sed -i.bak 's/${CARTS_RAM_LIMITS}/'$CARTS_RAM_LIMITS'/' ./drivers/tmp/deploy/docker-compose.yml
  #sed -i.bak 's/${CARTS_RAM_RESERVATIONS}/'$CARTS_RAM_RESERVATIONS'/' ./drivers/tmp/deploy/docker-compose.yml

  rm ./drivers/tmp/deploy/docker-compose.yml.bak

  # create a folder for the new test and copy the tmp data
  mkdir -p ./drivers/$TEST_ID
  cp -aR ./drivers/tmp/* ./drivers/$TEST_ID
  rm -rf ./drivers/tmp/*

  # Compile and package for deploy the faban driver
  echo "Compiling the Faban driver"
  cwd=$(pwd)
  cd ./drivers/$TEST_ID
  ant deploy.jar
  cd "$cwd"

  # create a folder for the test
  mkdir -p ./to_execute/$TEST_ID
  # copy the driver jarm run.xml and deployment descriptor
  cp ./drivers/$TEST_ID/build/$TEST_ID.jar ./to_execute/$TEST_ID
  cp ./drivers/$TEST_ID/config/run.xml ./to_execute/$TEST_ID
  cp ./drivers/$TEST_ID/deploy/docker-compose.yml ./to_execute/$TEST_ID
  cp ./drivers/$TEST_ID/*.yml ./to_execute/$TEST_ID
  
}

function execute_tests()
{
  FABAN_IP=$(getProperty "faban.ip")

  if [[ ! -z "$4" ]]
  then
    FABAN_IP=$4
  fi

  echo "Faban IP : $FABAN_IP"

  if [[ ! -z "$3" ]]
  then
    TENANT=$3
    echo "Tenant : $TENANT"
  fi

  if [[ ! -z "$2" ]]
  then
    PROPERTY_FILE=$2
    echo "Property file : $PROPERTY_FILE"
  fi

  STACK_NAME=$1

  FABAN_PORT=9980 #tmp

  echo "Get harness IP"
  IFS='  '
  TMP=($(docker service inspect $(docker service ls --filter name="${STACK_NAME}_faban-harness_${TENANT}" --format '{{.ID}}') --format '{{range $value := .Endpoint.VirtualIPs}} {{$value.Addr}} {{end}}'))
  
  echo $TMP
  TMP=${TMP[0]}
  IFS="/"
  HARNESS_IP=(${TMP[0]})
  echo "Harness IP : $HARNESS_IP"
  IFS=" "

  FABAN_MASTER="http://${FABAN_IP}:${FABAN_PORT}/";
  echo $FABAN_MASTER
  FABAN_CLIENT="./faban/benchflow-faban-client/target/benchflow-faban-client.jar"

  SUT_IP=$(getProperty "sut.ip")
  SUT_PORT=$(getProperty "sut.port")
  STAT_COLLECTOR_PORT=$(getProperty "stat.collector.port")


  echo "Launching on ${COMMAND}"
  for D in `find ./to_execute/${STACK_NAME}_${TENANT}_* -type d`; do
      if [ -d "${D}" ]; then
          echo $D
          arrD=(${D//\// })
          TEST_ID=${arrD[2]} 
          echo "Starting test: $TEST_ID"
	 
          
          # IF the system successfully deployed, then start the test

          test_name=$TEST_ID
          driver="to_execute/$TEST_ID/$TEST_ID.jar"
          driver_conf="to_execute/$TEST_ID/run.xml"
          deployment_descriptor="to_execute/$TEST_ID/docker-compose.yml"

          echo "Deploying the load driver"

          # Deploy and start the test
          echo java -jar $FABAN_CLIENT $FABAN_MASTER deploy $test_name $driver $driver_conf
          java -jar $FABAN_CLIENT $FABAN_MASTER deploy $test_name $driver $driver_conf | (read RUN_ID ; echo $RUN_ID > $D/RUN_ID.txt)

          RUN_ID=$(cat $D/RUN_ID.txt)
          # cleanup
          rm $D/RUN_ID.txt

          echo "Run ID: $RUN_ID"

          # Start the resource data collection
          echo "Data collection disabled: "
          #curl http://$SUT_IP:$STAT_COLLECTOR_PORT/start
          echo ""

          STATUS=""

  	  if [[ ! -z "$TENANT" ]]
          then
	        echo "Deploy agents on $STACK_NAME"
                export TENANT=$TENANT
          	cwd=$(pwd)
          	cd ./to_execute/$TEST_ID
          	export DESTINATION="$SUT_IP:$SUT_PORT"
          	echo "docker stack deploy --compose-file=bpm-docker-compose-agent.yml $STACK_NAME"
          	docker stack deploy --compose-file=bpm-docker-compose-agent.yml $STACK_NAME
          	cd "$cwd"
	  fi
          echo "Waiting for the test to be completed"

          # Wait for the test to be done
          while [ "$STATUS" != "COMPLETED" -a "$STATUS" != "KILLED" ];
          do 
              sleep 15
              # Get test status
              java -jar ./faban/benchflow-faban-client/target/benchflow-faban-client.jar $FABAN_MASTER status $RUN_ID | (read STATUS ; echo $STATUS > $D/STATUS.txt)
              STATUS=$(cat $D/STATUS.txt)
              echo "Current STATUS: $STATUS"
              # cleanup
              rm $D/STATUS.txt
          done

          # Stop the resource data collection and store the data
          echo "Data collection disabled: "
          #curl http://$SUT_IP:$STAT_COLLECTOR_PORT/stop
          echo ""

          # saving test results
          echo "Saving test results"
          mkdir -p ./executed/$TEST_ID/faban
          java -jar ./faban/benchflow-faban-client/target/benchflow-faban-client.jar $FABAN_MASTER info $RUN_ID > executed/$TEST_ID/faban/runInfo.txt
          curl $FABAN_MASTER"output/$RUN_ID/summary.xml" |gzip > executed/$TEST_ID/faban/summary.xml
          curl $FABAN_MASTER"output/$RUN_ID/detail.xan" |gzip  > executed/$TEST_ID/faban/detail.xan
          curl $FABAN_MASTER"output/$RUN_ID/log.xml" |gzip > executed/$TEST_ID/faban/log.xml
          mkdir -p ./executed/$TEST_ID/stats
          # curl http://$SUT_IP:$STAT_COLLECTOR_PORT/data > executed/$TEST_ID/stats/cpu.txt
          #cp ./services/stats/cpu.txt ./executed/$TEST_ID/stats/cpu.txt

          mv ./to_execute/$TEST_ID/ ./executed/$TEST_ID/definition

      fi
  done

}

function help_me()
{
  echo "Usage Examples: "
  echo ""
  echo "Generate Test: ./benchflow.sh generate_test <NUM_USERS> <CARTS_REPLICAS> <CARTS_CPUS_LIMITS> <CARTS_CPUS_RESERVATIONS> <CARTS_RAM_LIMITS> <CARTS_RAM_RESERVATIONS>"
  echo "Execute Tests (on Console): ./benchflow.sh execute_tests"
  echo "Execute Tests (background): nohup ./benchflow.sh execute_tests > log.out 2> log.err &"
}

#-----Business Logic functions----#

#-----Function selector----#

if [[ ! -z "$1" ]]
then
  if [[ "help" == "$1" ]]
  then
     (help_me)
  elif ( [[ "generate_test" == "$1" ]])
  then
     (generate_test $2 $3 $4 $5 $6 $7 $8 $9 "${10}" "${11}")
  elif ( [[ "execute_tests" == "$1" ]])
  then
     (execute_tests $2 $3 $4 $5)
  fi
fi

#-----Function selector----#
