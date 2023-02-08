#!/bin/bash

PROJECT_IMAGE=$1
CONTEXT_PATH=$2

echo "#### show PROJECT_IMAGE ${1} of env1 ####"
echo "#### show CONTEXT_PATH ${2} of env2 ####"
echo "#### Running the ${0} script ####"

DOCKER_TAG_LATEST=latest

DOCKER_TAG=${CI_COMMIT_TAG}
if [ "${DOCKER_TAG}" = '' ]; then
    # Branch trigger
    DOCKER_TAG=${CI_COMMIT_SHORT_SHA}
    DOCKER_TAG_LATEST=${CI_COMMIT_BRANCH}-latest
fi

DOCKER_FILE_PATH=""
if [ "${DOCKER_FILE}" != '' ]; then
    DOCKER_FILE_PATH="-f ${DOCKER_FILE}"
fi

run-slack-notify.bash "BEGIN" "N/A" "build"

#Pass ACCOUNT and TOKEN arguments for downloading NPM module from private GAR, 
#no matter if we need it or not.
SA_NAME="gitlab-runner@evermed-devops-prod.iam.gserviceaccount.com"
SA_TOKEN=$(gcloud auth print-access-token) #--impersonate-service-account ${SA_NAME}
DOCKER_ARGUMENTS="--build-arg ACCOUNT=${SA_NAME} --build-arg TOKEN=${SA_TOKEN}"

docker build -t ${PROJECT_IMAGE}:${DOCKER_TAG} -t ${PROJECT_IMAGE}:${DOCKER_TAG_LATEST} ${DOCKER_ARGUMENTS} ${CONTEXT_PATH} ${DOCKER_FILE_PATH}
retVal=$?
if [ $retVal -ne 0 ]; then
    run-slack-notify.bash "END" "ERROR" "build"
    exit 1
fi

docker push ${PROJECT_IMAGE}:${DOCKER_TAG}
retVal=$?
if [ $retVal -ne 0 ]; then
    run-slack-notify.bash "END" "ERROR" "build"
    exit 1
fi

docker push ${PROJECT_IMAGE}:${DOCKER_TAG_LATEST}
retVal=$?
if [ $retVal -ne 0 ]; then
    run-slack-notify.bash "END" "ERROR" "build"
    exit 1
fi

###### Start cleanup unused docker image ####
## To cleanup disk space
#docker image rm ${PROJECT_IMAGE}:${DOCKER_TAG_LATEST}
#retVal=$?
#if [ $retVal -ne 0 ]; then
#    run-slack-notify.bash "END" "ERROR" "build"
#    exit 1
#fi

#docker image rm ${PROJECT_IMAGE}:${DOCKER_TAG}
#retVal=$?
#if [ $retVal -ne 0 ]; then
#    run-slack-notify.bash "END" "ERROR" "build"
#    exit 1
#fi
###### End cleanup unused docker image ####

run-slack-notify.bash "END" "SUCCESS" "build"
echo "SYSTEM_DOCKER_IMAGE_TAG=${DOCKER_TAG}" >> ${SYSTEM_STATE_FILE}
