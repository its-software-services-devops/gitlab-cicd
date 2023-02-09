#!/bin/bash

GCR1=asia.gcr.io
GCR2=gcr.io
GAR=asia-southeast1-docker.pkg.dev

echo "#### Running the ${0} script ####"

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GCR1}
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GCR2}
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${GAR}

git config --global user.email "devops-cicd@abcdefg.io"
git config --global user.name "devops-cicd"
