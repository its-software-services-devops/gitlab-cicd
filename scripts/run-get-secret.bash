#!/bin/bash

# run-get-secret <project> <secret-name> <file-name-with-path>

GCP_PROJECT=$1
SECRET_NAME=$2
SECRET_FILE=$3

if [ "${GCP_PROJECT}" = '' ]; then
    echo "Please run : run-get-secret.bash <project> <secret-name> <file-name-with-path>"
    exit 1
fi

if [ "${SECRET_NAME}" = '' ]; then
    echo "Please run : run-get-secret.bash <project> <secret-name> <file-name-with-path>"
    exit 1
fi

if [ "${SECRET_FILE}" = '' ]; then
    echo "Please run : run-get-secret.bash <project> <secret-name> <file-name-with-path>"
    exit 1
fi

echo "Getting secret from project [${GCP_PROJECT}], secret [${SECRET_NAME}] to file [${SECRET_FILE}]..."
SECRET=$(gcloud secrets versions access latest --project="${GCP_PROJECT}" --secret="${SECRET_NAME}")

echo "${SECRET}" > "${SECRET_FILE}"
