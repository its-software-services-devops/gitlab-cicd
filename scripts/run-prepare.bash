#!/bin/bash

GCR=asia.gcr.io
GAR=asia-southeast1-docker.pkg.dev

echo "#### Running the ${0} script ####"

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GCR}
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GAR}

git config --global user.email "devops-cicd@everapp.io"
git config --global user.name "devops-cicd"
