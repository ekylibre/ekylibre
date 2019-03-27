#! /usr/bin/env bash
curl --user ${CIRCLE_TOKEN}: \
    --request POST \
    --form revision=b2471dd54f\
    --form config=@config.yml \
    --form notify=false \
        https://circleci.com/api/v1.1/project/github/ekylibre/ekylibre/tree/master
