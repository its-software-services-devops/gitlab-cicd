#!/bin/bash

echo "#### Running the ${0} script ####"

if [ "${CLOUD_TYPE}" = 'gcp' ]; then
    GCR1=asia.gcr.io
    GCR2=gcr.io
    GAR=asia-southeast1-docker.pkg.dev

    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

    gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GCR1}
    gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GCR2}
    gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GAR}
elif [ "${CLOUD_TYPE}" = 'aws' ]; then
    # The CICD_* variables are defined in the GitLab/GitHub env setting

    aws configure set aws_access_key_id "${CICD_AWS_ACCESS_KEY}" --profile cicd-devops && \
    aws configure set aws_secret_access_key "${CICD_AWS_SECRET_KEY}" --profile cicd-devops && \
    aws configure set region "${CICD_AWS_REGION}"

    aws ecr get-login-password --region ${CICD_AWS_REGION} | docker login --username AWS --password-stdin ${CICD_AWS_REGISTRY_HOST}
fi

git config --global user.email "devops-cicd@abcdefg.com"
git config --global user.name "devops-cicd"
