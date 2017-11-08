#!/usr/bin/env bash
#
declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
declare SCRIPTNAME=$(basename "$SCRIPT"); # This script's name

[ -z $1 ] && echo -e "Usage:   ./${SCRIPTNAME} <database server host name> ['root']" && exit 1;

export RDBMS_ADMIN_PWD=$(jq -r .RDBMS_ADMIN_PWD ~/.ssh/deploy_vault/${1}/secrets.json);
export RDBMS_PWD=$(jq -r .RDBMS_PWD ~/.ssh/deploy_vault/${1}/secrets.json);
export RDBMS_OWNER=$(jq -r .virtual_hosts[\"${1}\"].sql.RDBMS_OWNER ~/.vulcan/index.json);
export RDBMS_HST=$(jq -r .virtual_hosts[\"${1}\"].sql.RDBMS_HST ~/.vulcan/index.json);
export RDBMS_DB=$(jq -r .virtual_hosts[\"${1}\"].sql.RDBMS_DB ~/.vulcan/index.json);

declare PWD=${RDBMS_PWD};
declare USR=${RDBMS_OWNER};
[ ! -z $2 ] && PWD=${RDBMS_ADMIN_PWD} && USR='root';
echo -e "mysql -h ${RDBMS_HST} -u ${USR} -p${PWD}  ${RDBMS_DB}";
mysql -h ${RDBMS_HST} -u ${USR} -p${PWD}  ${RDBMS_DB};

