#!/bin/bash

#Run this script as dot script
ENV_FILE=/tmp/ci.env

if [ -f "${ENV_FILE}" ]
then
   echo "File ${ENV_FILE} already exist, export all variables in file."
else
   CI_COMMIT_SHORT_SHA=$(git rev-parse HEAD | cut -c1-8)
   CI_COMMIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   CI_COMMIT_TAG=$(git tag --points-at HEAD)

   echo "CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}" > ${ENV_FILE}
   echo "CI_COMMIT_BRANCH=${CI_COMMIT_BRANCH}" >> ${ENV_FILE}
   echo "CI_COMMIT_TAG=${CI_COMMIT_TAG}" >> ${ENV_FILE}
fi

set -o allexport; source ${ENV_FILE}; set +o allexport
