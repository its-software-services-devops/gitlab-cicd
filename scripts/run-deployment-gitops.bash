#!/bin/bash

# export GITOPS_TAG_VARIABLES="image-tag1,image-tag2"
# run-deployment-gitops.bash development Devops/cicd/gitlab-runner-demo-deployment.git
# Note : The GIT_URL_GITOPS env variable is set in the Gitlab UI (CICD section - Group DevOps)
set -x

# The SYSTEM_STATE_FILE is defined in Dockerfile, file populated from CI build
set -o allexport; source "${SYSTEM_STATE_FILE}"; set +o allexport

ENVIRONMENT=$1
ARGOCD_BRANCH=$1
GIT_URI=$2

VALUE_FILE_DIR="manifests"
VALUE_FILE=${VALUE_FILE_DIR}/values-tags-${ARGOCD_BRANCH}.yaml

# Variable DOCKER_TAG is defined in SYSTEM_STATE_FILE
IMAGE_TAG=${DOCKER_TAG}

echo "Running using GIT_URI=[${GIT_URI}], IMAGE_TAG=[${IMAGE_TAG}]"

git config --global user.email "cicd-auto@mycomapny.com"
git config --global user.name "CICD"

git clone "${GIT_URL_GITOPS}/${GIT_URI}" deployment
cd deployment
git checkout ${ARGOCD_BRANCH}

cp ${VALUE_FILE_DIR}/values-template.yaml ${VALUE_FILE}
for var in ${GITOPS_TAG_VARIABLES//,/ }
do
    sed -i "s#<<${var}>>#${IMAGE_TAG}#g" ${VALUE_FILE}
done

ls -lrt
cat ${VALUE_FILE}
git add ${VALUE_FILE}; git commit --m "Update image tag by auto deploy script"; git push
