#!/bin/bash

echo "#### Running the ${0} script ####"

CLONE_SSH_URI=$1
TO_FOLDER=$2

URL=https://gitlab-ci-token:${GITLAB_TOKEN}@gitlab.com/ever-medical-technologies/${CLONE_SSH_URI}
git clone ${URL} ${TO_FOLDER}
