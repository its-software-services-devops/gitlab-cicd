#!/bin/bash

# slack-notify.bash <begin|end> <status>

STAGE=$1
STATUS=$2
PHASE=$3
STATUS_EMOJI=""

TMP_TEMPLATE=/tmp/template.json
BQ_TEMPLATE=/tmp/bq_template.json
BQ_TEMPLATE_ND=/tmp/bq_template_nd.json
SLACK_URL=""
CI_COMMIT_DESCRIPTION=$(git log --format=%B -n 1 | head -1)
JOB_NAME=$(basename ${CI_JOB_URL})
REPO_NAME=$(basename ${CI_REPOSITORY_URL})
TMP_START_DTM=/tmp/start-dtm.txt
TMP_START_EPOC=/tmp/start-epoc.txt

HEADER="[${STAGE}] CI build"
SRC_TEMPLATE=/data/job-build-template.json
SRC_BQ_TEMPLATE=/data/job-stat-template.json
if [ "${PHASE}" = 'deploy' ]; then
    SRC_TEMPLATE="/data/job-deploy-template.json"
    HEADER="[${STAGE}] CD deploy"
fi

# For SLACK notification
cp ${SRC_TEMPLATE} ${TMP_TEMPLATE}
sed -i "s#<STATUS_EMOJI>#${STATUS_EMOJI}#g" ${TMP_TEMPLATE}
sed -i "s#<STATUS>#${STATUS}#g" ${TMP_TEMPLATE}
sed -i "s#<HEADER>#${HEADER}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_REPOSITORY_URL>#${CI_REPOSITORY_URL}#g" ${TMP_TEMPLATE}
sed -i "s#<REPO_NAME>#${REPO_NAME}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_JOB_URL>#${CI_JOB_URL}#g" ${TMP_TEMPLATE}
sed -i "s#<JOB_NAME>#${JOB_NAME}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_COMMIT_REF_NAME>#${CI_COMMIT_REF_NAME}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_COMMIT_SHORT_SHA>#${CI_COMMIT_SHORT_SHA}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_COMMIT_DESCRIPTION>#${CI_COMMIT_DESCRIPTION}#g" ${TMP_TEMPLATE}
sed -i "s#<CI_COMMIT_AUTHOR>#${CI_COMMIT_AUTHOR}#g" ${TMP_TEMPLATE}
sed -i "s#<GKE_PROJECT_ID>#${GKE_PROJECT_ID}#g" ${TMP_TEMPLATE}
sed -i "s#<DEPLOY_NAMESPACE>#${DEPLOY_NAMESPACE}#g" ${TMP_TEMPLATE}
sed -i "s#<GKE_CLUSTER_NAME>#${GKE_CLUSTER_NAME}#g" ${TMP_TEMPLATE}

curl -X POST -H 'Content-type: application/json' --data "@${TMP_TEMPLATE}" ${SLACK_URL}


if [ "${STAGE}" = 'BEGIN' ]; then
    echo -n "$(date -u +"%FT%T.000Z")" > ${TMP_START_DTM}
    echo -n "$(date +%s)" > ${TMP_START_EPOC}
else
    # END
    JOB_START_DTM=$(cat ${TMP_START_DTM})
    JOB_END_DTM=$(date -u +"%FT%T.000Z")
    JOB_START_EPOC=$(cat ${TMP_START_EPOC})
    JOB_END_EPOC=$(date +%s)

    JOB_DURASION_SEC="$((${JOB_END_EPOC}-${JOB_START_EPOC}))"

    # For statistic in BigQuery
    cp ${SRC_BQ_TEMPLATE} ${BQ_TEMPLATE}
    sed -i "s#<JOB_START_DTM>#${JOB_START_DTM}#g" ${BQ_TEMPLATE}
    sed -i "s#<JOB_END_DTM>#${JOB_END_DTM}#g" ${BQ_TEMPLATE}
    sed -i "s#<JOB_DURASION_SEC>#${JOB_DURASION_SEC}#g" ${BQ_TEMPLATE}
    sed -i "s#<STATUS>#${STATUS}#g" ${BQ_TEMPLATE}
    sed -i "s#<PHASE>#${PHASE}#g" ${BQ_TEMPLATE}
    sed -i "s#<HEADER>#${HEADER}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_REPOSITORY_URL>##g" ${BQ_TEMPLATE} # DO NOT show it because token is in the URL
    sed -i "s#<REPO_NAME>#${REPO_NAME}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_JOB_URL>#${CI_JOB_URL}#g" ${BQ_TEMPLATE}
    sed -i "s#<JOB_NAME>#${JOB_NAME}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_COMMIT_REF_NAME>#${CI_COMMIT_REF_NAME}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_COMMIT_SHORT_SHA>#${CI_COMMIT_SHORT_SHA}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_COMMIT_DESCRIPTION>#${CI_COMMIT_DESCRIPTION}#g" ${BQ_TEMPLATE}
    sed -i "s#<CI_COMMIT_AUTHOR>#${CI_COMMIT_AUTHOR}#g" ${BQ_TEMPLATE}
    sed -i "s#<GKE_PROJECT_ID>#${GKE_PROJECT_ID}#g" ${BQ_TEMPLATE}
    sed -i "s#<DEPLOY_NAMESPACE>#${DEPLOY_NAMESPACE}#g" ${BQ_TEMPLATE}
    sed -i "s#<GKE_CLUSTER_NAME>#${GKE_CLUSTER_NAME}#g" ${BQ_TEMPLATE}
    
    echo $(cat ${BQ_TEMPLATE}) > ${BQ_TEMPLATE_ND} # Convert to a single line JSON
    cat ${BQ_TEMPLATE_ND}
fi
