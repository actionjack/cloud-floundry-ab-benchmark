#!/bin/bash -e

# set -x # Uncomment for debug

#
# Executes a ab test in a remote hosts and gathers CPU metrics
#

# Example:
#  DEPLOY_ENV=hector270715 \
#  TARGET_HOST=10.129.0.72 \
#  SOURCE_HOST=hector270715.cf2.paas.alphagov.co.uk \
#  ./script.sh

die(){
  echo $@
  exit 1
}

DEPLOY_ENV=${DEPLOY_ENV}
[ "$DEPLOY_ENV" ] || die "Must specify DEPLOY_ENV"
TARGET_HOST=${TARGET_HOST}
[ "$TARGET_HOST" ] || die "Must specify TARGET_HOST"
SOURCE_HOST=${SOURCE_HOST}
[ "$SOURCE_HOST" ] || die "Must specify SOURCE_HOST"

TARGET_URL=${TARGET_URL:-http://$TARGET_HOST/}

# Result target directory
TARGET_DIR=${TARGET_DIR:-/tmp/benchmark-test}
if [[ ! -d ${TARGET_DIR} ]]
  then mkdir ${TARGET_DIR}
fi

# Host header to pass in the request, to hit the backend apps:
HOST_HEADER=${HOST_HEADER:-testapp.$DEPLOY_ENV.cf2.paas.alphagov.co.uk}

# Enable keepalive: -k
ENABLE_KEEP_ALIVE=${ENABLE_KEEP_ALIVE:-}
# Extra AB Options.
EXTRA_AB_OPTIONS=${EXTRA_AB_OPTIONS:-}

NUM_REQUESTS=${NUM_REQUESTS:-500}
CONCURRENT_REQUESTS=${CONCURRENT_REQUESTS:-20}
TIMEOUT_REQUEST=${TIMEOUT_REQUEST:-3000}

# Special flags to pass to SSH
SSH_FLAGS=${SSH_FLAGS:--l ubuntu }
SCP_FLAGS=${SCP_FLAGS:--o User=ubuntu }

#########################################################################

# Fail quick if we can not ssh
check_remote_hosts() {
  echo "Trying to ssh to $TARGET_HOST"
  echo ssh -T $SSH_FLAGS $SOURCE_HOST true
  ssh -T $SSH_FLAGS $SOURCE_HOST true < /dev/null
#  echo ssh -T $SSH_FLAGS $TARGET_HOST true
#  ssh -T $SSH_FLAGS $TARGET_HOST true < /dev/null
}

run_test_plan() {
  AB_COMMAND="
time ab -s $TIMEOUT_REQUEST -n $NUM_REQUESTS -c $CONCURRENT_REQUESTS
 ${ENABLE_KEEP_ALIVE:+-k}
 -g /tmp/ab_output.tsv
 ${HOST_HEADER:+-H 'Host: $HOST_HEADER'}
 ${TARGET_URL}
"
  echo "Executing: '$AB_COMMAND'"
  ssh -T $SSH_FLAGS $SOURCE_HOST $AB_COMMAND | tee $TARGET_DIR/ab_report.txt
  scp -q $SCP_FLAGS $SOURCE_HOST:/tmp/ab_output.tsv $TARGET_DIR/
}


check_remote_hosts
run_test_plan
