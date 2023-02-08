#!/bin/bash

set -x

GIT_URI=$1
IMAGE_TAG=$2 # AUTO, GIT
MODE=$3 # DIRECT, GITOPS, TRIGGER
GIT_GITOPS_URI="devops/deployment/argocd-manifests.git" # Central git repo for ArgoCD

echo "Running using GIT_URI=[${GIT_URI}], IMAGE_TAG=[${IMAGE_TAG}], MODE=[${MODE}]"

TO_FOLDER=temp-cloned
ALIAS=repo
ALIAS_EXT=repo-ext
VERSION_CFG_FILE=version.config
INFO_FILE=info.manifest
CWD=$(pwd)
HELM_TEMPLATE=${CWD}/manifest.yaml
HELM_EXT_TEMPLATE=${CWD}/manifest-ext.yaml
GITOPS_FOLDER=gitops-cloned
GITOPS_MANIFESTS=manifests.yaml

ENVIRONMENT=$(determine-env.pl)
if [ "${ENVIRONMENT}" = 'UNDEFINED' ]; then
    echo "Unable to map environment from branch or tag!!!"
    exit 1
fi

echo "Deploying to environment [${ENVIRONMENT}]..."
CHECKOUT_BRANCH="deploy/${ENVIRONMENT}"

COMMON_CONFIG_FILE="configs/config-common.cfg"
CUSTOM_CONFIG_FILE="configs/config-${ENVIRONMENT}.cfg"

generate_image_pull_secret () {

    kubectl create ns ${DEPLOY_NAMESPACE}

    DOCKER_SERVER="asia.gcr.io"
    if [ "${CD_DOCKER_SERVER}" != '' ]; then
        # Use from GAR instead
        # asia-southeast1-docker.pkg.dev
        DOCKER_SERVER="${CD_DOCKER_SERVER}"
    fi

    echo "DOCKER_SERVER=[${DOCKER_SERVER}], CD_DOCKER_SERVER=[${CD_DOCKER_SERVER}]"
    
    # Check if exist, if yes then replace, otherwise create.
    SECRET_NAME=gcr-image-pull-secret
    SECRET_COUNT=$(kubectl get secret -n ${DEPLOY_NAMESPACE} ${SECRET_NAME} | grep ${SECRET_NAME} | wc -l)
    
    if [ "${SECRET_COUNT}" == '1' ]; then
        # Already exist so delete the existing one first
        echo "Secret count = [${SECRET_COUNT}], deleting secret ${SECRET_NAME} before creating the new one"
        kubectl delete secret ${SECRET_NAME} -n ${DEPLOY_NAMESPACE}
    fi

    set +x # Don't dump secret
    kubectl create secret docker-registry ${SECRET_NAME} -n ${DEPLOY_NAMESPACE} \
        --docker-server="${DOCKER_SERVER}" \
        --docker-username=_json_key \
        --docker-password="$(cat ${GOOGLE_APPLICATION_CREDENTIALS})" \
        --docker-email=required@but-not-used.everapp.io    
    set -x

    kubectl get node
    kubectl get secrets -n ${DEPLOY_NAMESPACE}
}


if [ "${IMAGE_TAG}" = 'AUTO' ]; then
    # Auto deploy logic here

    set -o allexport; source "${SYSTEM_STATE_FILE}"; set +o allexport
    run-git-clone.bash ${GIT_URI} ${TO_FOLDER}

    # Checkout branch per env
    cd ${TO_FOLDER}
    git checkout ${CHECKOUT_BRANCH}
    ls -lrt

    # Load config per env
    set -o allexport; source "${COMMON_CONFIG_FILE}"; set +o allexport
    set -o allexport; source "${CUSTOM_CONFIG_FILE}"; set +o allexport

    # SYSTEM_DOCKER_IMAGE_TAG is defined in this file ${SYSTEM_STATE_FILE}
    ##echo "${HELM_DOCKER_VERSION_FIELD}=${SYSTEM_DOCKER_IMAGE_TAG}" > ${VERSION_CFG_FILE}
    generate-version-file.pl "$(pwd)/${VERSION_CFG_FILE}"

    echo "$(date)" > ${INFO_FILE}

    # push branch back here
    git pull; git add ${VERSION_CFG_FILE} ${INFO_FILE}; git commit --m 'Change by autodeploy script'; git push

elif [ "${IMAGE_TAG}" = 'GIT' ]; then
    # Load config per env
    set -o allexport; source "${COMMON_CONFIG_FILE}"; set +o allexport
    set -o allexport; source "${CUSTOM_CONFIG_FILE}"; set +o allexport
fi

run-slack-notify.bash "BEGIN" "N/A" "deploy"

# Generate Helm template

CHART_NAME=$(basename ${HELM_REPO})
if [ "${HELM_CHART_NAME}" != '' ]; then
    # Defined in the git repository 
    echo "Using chart [${HELM_CHART_NAME}]"
    CHART_NAME=${HELM_CHART_NAME}
fi 

HELM_ENV_VALUE_FILE="configs/values-${ENVIRONMENT}.yaml"
HELM_CMN_VALUE_FILE="values.yaml"

HELM_EXT_ENV_VALUE_FILE="configs/extension-${ENVIRONMENT}.yaml"
HELM_EXT_CMN_VALUE_FILE="extension.yaml"

IMAGE_TAG_SET=$(generate-tag-set.pl "$(pwd)/${VERSION_CFG_FILE}")

helm repo add ${ALIAS} ${HELM_REPO}
helm fetch ${ALIAS}/${CHART_NAME}

helm template ${ALIAS}/${CHART_NAME} --version ${HELM_CHART_VERSION} \
    --namespace ${DEPLOY_NAMESPACE} \
    -f ${HELM_CMN_VALUE_FILE} \
    -f ${HELM_ENV_VALUE_FILE} \
    ${IMAGE_TAG_SET} \
    --skip-tests \
    --name-template=${ENVIRONMENT} > ${HELM_TEMPLATE}

retVal=$?
if [ $retVal -ne 0 ]; then
    run-slack-notify.bash "END" "ERROR" "deploy"
    exit 1
fi

# Added Helm extentions
if [ "${HELM_EXT_REPO}" != '' ]; then
    # HELM_EXT_REPO and HELM_EXT_CHART_VERSION are in the env variables

    EXT_CHART_NAME=$(basename ${HELM_EXT_REPO})

    echo "Found Helm extension setting HELM_EXT_REPO=[${HELM_EXT_REPO}], EXT_CHART_NAME=[${EXT_CHART_NAME}]"

    helm repo add ${ALIAS_EXT} ${HELM_EXT_REPO}
    helm fetch ${ALIAS_EXT}/${EXT_CHART_NAME}

    helm template ${ALIAS_EXT}/${EXT_CHART_NAME} --version ${HELM_EXT_CHART_VERSION} \
        --namespace ${DEPLOY_NAMESPACE} \
        -f ${HELM_EXT_CMN_VALUE_FILE} \
        -f ${HELM_EXT_ENV_VALUE_FILE} \
        --name-template=${ENVIRONMENT} > ${HELM_EXT_TEMPLATE}

    retVal=$?
    if [ $retVal -ne 0 ]; then
        run-slack-notify.bash "END" "ERROR" "deploy"
        exit 1
    fi
fi


cat ${HELM_TEMPLATE}
echo "======= START EXTENSIONS ========"
HELM_EXT_TEMPLATE_CTN=$(cat ${HELM_EXT_TEMPLATE})
cat ${HELM_EXT_TEMPLATE}
echo "======= END EXTENSIONS ========"

if [ "${PLATFORM_TYPE}" = 'cloud-run' ]; then
    if [ "${MODE}" = 'DIRECT' ]; then
        gcloud run services replace "${HELM_TEMPLATE}" --region ${CLOUDRUN_REGION} --project ${CLOUDRUN_PROJECT_ID}

        retVal=$?
        if [ $retVal -ne 0 ]; then
            run-slack-notify.bash "END" "ERROR" "deploy"
            exit 1
        fi
    fi
else
    if [ "${PLATFORM_TYPE}" = 'k8s' ]; then
        #Deploy to native K8S cluster
        create-kubeconfig.bash
    else
        # Fallback to GKE here
        HA_FLAG="--region ${GKE_REGION}"
        if [ "${GKE_HA_TYPE}" = 'zone' ]; then
            HA_FLAG="--zone ${GKE_ZONE}"
        fi
        gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --project ${GKE_PROJECT_ID} ${HA_FLAG}
    fi

    if [ "${MODE}" = 'DIRECT' ]; then
        # kubectl apply here
        generate_image_pull_secret
        kubectl apply -f ${HELM_TEMPLATE} -n ${DEPLOY_NAMESPACE}

        if [ "${HELM_EXT_TEMPLATE_CTN}" != '' ]; then
            echo "Extension manifest does not empty"
            kubectl apply -f ${HELM_EXT_TEMPLATE} -n ${DEPLOY_NAMESPACE}
        fi

        retVal=$?
        if [ $retVal -ne 0 ]; then
            run-slack-notify.bash "END" "ERROR" "deploy"
            exit 1
        fi
    fi

    if [ "${MODE}" = 'GITOPS' ]; then
        cd ${CWD}

        # Derived from config env
        GITOPS_BRANCH="${GKE_PROJECT_ID}/${GKE_CLUSTER_NAME}/${DEPLOY_NAMESPACE}/${CI_PROJECT_NAME}"
        PUSH_OPTION=""

        run-git-clone.bash ${GIT_GITOPS_URI} ${GITOPS_FOLDER}

        # Checkout branch per env
        cd ${GITOPS_FOLDER}
        
        git checkout ${GITOPS_BRANCH}
        retVal=$?
        if [ $retVal -ne 0 ]; then
            # Branch does not exist
            echo "Branch [${GITOPS_BRANCH}] does not exist, will create one."
            git checkout -b ${GITOPS_BRANCH}

            PUSH_OPTION="--set-upstream origin ${GITOPS_BRANCH}"
        fi

        echo "Git push option is [${PUSH_OPTION}]"
        ls -lrt

        echo "$(date)" > ${INFO_FILE}
        cp ${HELM_TEMPLATE} ${GITOPS_MANIFESTS}
        ls -lrt

        generate_image_pull_secret

        # push branch back here
        git pull; git add ${GITOPS_MANIFESTS} ${INFO_FILE}; git commit --m 'Change by autodeploy script'; git push ${PUSH_OPTION}
    fi
fi

run-slack-notify.bash "END" "SUCCESS" "deploy"
