#!/usr/bin/env bash
#
declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
declare SCRIPTNAME=$(basename "$SCRIPT"); # This script's name

if [ -z ${1} ]; then
  echo -e "

  ${SCRIPT}
  ${SCRIPTPATH}
  ${SCRIPTNAME}
  ${PROJECTPATH}
  Must specify a remote virtual host URL. Eg; yoursite.yourpublic.work";
  exit 1;
else
  ${SCRIPTPATH}/target/PrepareTargetHost.sh  ${1};
  ${SCRIPTPATH}/target/DeployAppBundleToHost.sh  ${1};
fi;
