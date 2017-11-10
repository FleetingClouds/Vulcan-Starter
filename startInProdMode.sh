#!/usr/bin/env bash
#
declare SCRIPT=$(readlink -f "$0");
declare SCRIPTNAME=$(basename "$SCRIPT"); # This script's name
declare PROJECT_ROOT=$(dirname "$SCRIPT");  # Where this script resides

echo PROJECT_ROOT=${PROJECT_ROOT};

${PROJECT_ROOT}/.scripts/free.sh;
#
export PARMS_FILE="${HOME}/.vulcan/index.json";
#
[[ ! -f ${PARMS_FILE} ]] && echo -e "A parameters file '${PARMS_FILE}' is required." && exit;

source ${PROJECT_ROOT}/.scripts/utils.sh;
declare HOST_SERVER_NAME=$(jq -r '.mode' ${HOME}/.vulcan/index.json);



export SECRETS_FILE="${HOME}/.ssh/deploy_vault/${HOST_SERVER_NAME}/secrets.json";

if [[ ! ${CI} ]]; then
  if [[ ! -f ${SECRETS_FILE} ]]; then
    echo -e "Unable to find the file \"${SECRETS_FILE}\".\n";
    exit;
  fi;

  # source ${HOME}/.ssh/deploy_vault/${HOST_SERVER_NAME}/secrets.sh;
fi;

# collectBuildSecrets show;
collectJSONkeys ${SECRETS_FILE} ".";
export HOST_SERVER_PARMS=".virtual_hosts[\"${HOST_SERVER_NAME}\"]";
collectJSONkeys ${PARMS_FILE} "${HOST_SERVER_PARMS}.sql"; # show;
collectJSONkeys ${PARMS_FILE} "${HOST_SERVER_PARMS}.accounts"; # show;
collectJSONkeys ${PARMS_FILE} "${HOST_SERVER_PARMS}.protocol"; # show;


declare METEOR="${METEOR_CMD:-meteor}";
declare LOGS_DIR="${CIRCLE_ARTIFACTS:-/var/log/meteor}";
echo -e "Will write logs to : ${LOGS_DIR}";
if [[  ! -w ${LOGS_DIR}  ]]; then
  sudo mkdir -p ${LOGS_DIR};
  sudo chown $(whoami):$(whoami) ${LOGS_DIR};
  sudo chmod +rwx ${LOGS_DIR};
fi;
#
export RELEASE=$(cat ${PROJECT_ROOT}/.meteor/release | cut -d "@" -f 2);
export ANAME=$(cat package.json | jq -r .name);
export APP_NAME="${ANAME:-app}";
date > ${LOGS_DIR}/${APP_NAME}.log;
#
echo -e "Using meteor version : ${RELEASE}" | tee -a ${LOGS_DIR}/${APP_NAME}.log;
#
cd ${PROJECT_ROOT};
echo -e "  * * * CONFIGURATION FOR APP SERVER ; ${HOST_SERVER_NAME} * * *
   dialect: ${RDBMS_DIALECT},
connection: {
        port : ${RDBMS_PORT},
        host : ${RDBMS_HST},
    database : ${RDBMS_DB},
        user : ${RDBMS_UID},
    password : $(head -c $(( ${#RDBMS_PWD} - 4 )) /dev/zero | tr '\0' '*')${RDBMS_PWD:$(( ${#RDBMS_PWD} - 4 ))}
}
";

declare PKS_DIR_MIN_SIZE=150000;
declare PKS_DIR="node_modules";
mkdir -p ${PKS_DIR};
[[ $(du -s ${PKS_DIR} | cut -f1) -lt ${PKS_DIR_MIN_SIZE} ]] && meteor npm install;

sh .scripts/target/host_scripts/settings.json.template.sh > settings.json;

export ROOT_URL=${HOST_SERVER_PROTOCOL}://${HOST_SERVER_NAME}:${HOST_SERVER_PORT};

echo -e "export ROOT_URL='${ROOT_URL}';
export MONGO_URL='${MONGO_URL}'
${METEOR} run \
 --port ${HOST_SERVER_PORT} \
 --release ${RELEASE} \
 --settings=settings.json \
 2>&1 | tee -a ${LOGS_DIR}/${APP_NAME}.log;"


if [[ "$1" = "reset" ]]; then
  echo -e "Resetting the MongoDB database.";
  ${METEOR} reset;
else
  echo -e "Launching '${ROOT_URL}' . . .

  If you find you get stuck at
       'Starting your app...'
  then append 'reset' to the command to clear the problem: Eg.,
       ./startInProdMode.sh reset
  ";
fi;

${METEOR} run \
    --port ${HOST_SERVER_PORT} \
    --release ${RELEASE} \
    --settings=settings.json \
   2>&1 | tee -a ${LOGS_DIR}/${APP_NAME}.log;

