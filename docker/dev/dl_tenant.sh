#!/usr/bin/env bash
set -e

# Check params
if [[ 2 -ne $# ]];
then
    echo Missing args, needed: 2 found: $# >&2
    echo "Usage: bash docker/dev/dl_tenant.sh <env> <tenant>"
    exit 1
fi

# Init var
EKY_ENV=$1
TENANT=$2

ZIP_FILE="${TENANT}.zip"
ZIP_TEMP="${TENANT}.zip.temp"

DEPLOY_PATH="prod-current"
ARCHIVES_PATH="${DEPLOY_PATH}/tmp/archives"

SERVER="eky-${EKY_ENV}"


DEST_PATH="tmp/archives"


# Create and dl archive from server
if [[ ! -d ${DEST_PATH} ]]; then
    echo "Local archives path not found"
    exit 1
fi


ssh "${SERVER}" <<BASH
set -e
if [[ -d "${DEPLOY_PATH}" || -L "${DEPLOY_PATH}" ]];
then
    if [[ ! -d ${ARCHIVES_PATH} ]]; then
        echo "archive path not found" >&2
        exit 1
    fi
    if [[ -f "${ARCHIVES_PATH}/${ZIP_TEMP}" ]]; then
        echo "Temp file still present, maybe a previous run failed?"
        exit 1
    fi
    if [[ -f "${ARCHIVES_PATH}/${ZIP_FILE}" ]]; then
        echo Moving previous tenant file away temporarily
        mv "${ARCHIVES_PATH}/${ZIP_FILE}" "${ARCHIVES_PATH}/${ZIP_TEMP}"
    fi

    (
        cd "${DEPLOY_PATH}"
        RAILS_ENV=production /tmp/ekylibre/ekylibre-exec.sh bundle exec rake tenant:dump TENANT="${TENANT}"
    )

    exit 0
else
    echo Error, unable to find deploy folder >&2
    exit 1
fi
BASH

scp "${SERVER}:${ARCHIVES_PATH}/${ZIP_FILE}" "${DEST_PATH}"

ssh "${SERVER}" <<BASH
set -e
if [[ -f "${ARCHIVES_PATH}/${ZIP_TEMP}" ]]; then
    mv "${ARCHIVES_PATH}/${ZIP_TEMP}" "${ARCHIVES_PATH}/${ZIP_FILE}"
fi
BASH

# Apply to your local docker db
docker-compose down
docker-compose up -d db
sleep 5 # It's probably overkill to wait 5 sec, but it is to wait for db init
docker-compose run app bundle exec rake tenant:restore TENANT=${TENANT}
docker-compose down
