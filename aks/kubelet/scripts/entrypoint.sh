#!/bin/sh
# set -e

# nsenter --help
function nsenter_()   {
  nsenter --target 1 --mount --uts --pid -- $@
}
function nsenter_sh() {
  nsenter --target 1 --mount --uts --pid -- sh -c "$@"
}

DIR_SCRIPT=${DIR_SCRIPT:-/scripts}
DIR_HOST=${DIR_HOST:-/tmp/aks-setup}
MAIN_SCRIPT=${PY_SCRIPT:-setup.py}

cp $DIR_SCRIPT/*.py $DIR_HOST
nsenter_sh "python $DIR_HOST/$MAIN_SCRIPT"
# rm $DIR_HOST/*

tail -f /dev/null