#!/bin/bash
RESULT_FILENAME=$2
touch ${RESULT_FILENAME}.csv
docker run --env-file migration-scripts/azure_test.env --env RESULT_FILENAME=${RESULT_FILENAME} -v ${PWD}/${RESULT_FILENAME}.csv:/tmp/${RESULT_FILENAME}.csv -e TENANT_ID=$1 -e CREATE_TENANT=$3 move_tenant
