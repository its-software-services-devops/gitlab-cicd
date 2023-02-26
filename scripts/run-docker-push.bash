#!/bin/bash

PROJECT_IMAGE=$1
CONTEXT_PATH=$2

# To preserve env variables, run dot script
. create-ci-env.bash

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

# Check from ENV var
retVal = 0
if [ "${PROJECT_IMAGE_EXT}" != '' ]; then
    docker build -t ${PROJECT_IMAGE}:${DOCKER_TAG} -t ${PROJECT_IMAGE}:${DOCKER_TAG_LATEST} \
        -t ${PROJECT_IMAGE_EXT}:${DOCKER_TAG} -t ${PROJECT_IMAGE_EXT}:${DOCKER_TAG_LATEST} \
        ${CONTEXT_PATH} ${DOCKER_FILE_PATH}
    retVal=$?
else
    docker build -t ${PROJECT_IMAGE}:${DOCKER_TAG} -t ${PROJECT_IMAGE}:${DOCKER_TAG_LATEST} ${CONTEXT_PATH} ${DOCKER_FILE_PATH}
    retVal=$?
fi

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

if [ "${PROJECT_IMAGE_EXT}" != '' ]; then
    docker push ${PROJECT_IMAGE_EXT}:${DOCKER_TAG}
    retVal=$?
    if [ $retVal -ne 0 ]; then
        run-slack-notify.bash "END" "ERROR" "build"
        exit 1
    fi

    docker push ${PROJECT_IMAGE_EXT}:${DOCKER_TAG_LATEST}
    retVal=$?
    if [ $retVal -ne 0 ]; then
        run-slack-notify.bash "END" "ERROR" "build"
        exit 1
    fi
fi

run-slack-notify.bash "END" "SUCCESS" "build"
echo "SYSTEM_DOCKER_IMAGE_TAG=${DOCKER_TAG}" >> ${SYSTEM_STATE_FILE}
