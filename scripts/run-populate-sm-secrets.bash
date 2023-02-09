#!/bin/bash

GCP_PROJECT=$1
SECRET_NAME=$2
OUTPUT_FILE=$3

gcloud secrets versions access latest --project=${GCP_PROJECT} --secret="${SECRET_NAME}" > ${OUTPUT_FILE}
