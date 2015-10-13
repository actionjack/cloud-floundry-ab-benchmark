#!/bin/sh
SUITENAME=${1:-suite-unknown}
TARGET_URL=${TARGET_URL:-"http://10.0.0.14/"}
TIMEOUT_REQUEST=${TIMEOUT_REQUEST:-3000}

for CONCURRENT_REQUESTS in 200 300 400 500 1000 1500 2000 2500 3000 3500 4000; do

    echo ===================================================================
    echo ===================================================================
    echo ===================================================================
    echo ===================================================================
    date
    echo $CONCURRENT_REQUESTS
    echo ===================================================================
    echo ===================================================================
    echo ===================================================================
    echo ===================================================================

    export CONCURRENT_REQUESTS
    export NUM_REQUESTS=$(($CONCURRENT_REQUESTS * 30))

    DEPLOY_ENV=pulverize \
    TARGET_HOST=10.0.0.14 \
    SOURCE_HOST=104.155.55.13 \
    ENABLE_KEEP_ALIVE=yes \
    TARGET_URL=$TARGET_URL \
    TARGET_DIR=/tmp/test-suite-output/$NUM_REQUESTS-conc-$CONCURRENT_REQUESTS \
    ./execute_perf_test.sh
done
