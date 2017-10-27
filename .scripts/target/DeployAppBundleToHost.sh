#!/usr/bin/env bash
#
declare PRTY="~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nYourPublic App :: Deploy Bundle :: ";

declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
declare SCRIPTNAME=$(basename "$SCRIPT"); # This script's name
declare PROJECTPATH=$(readlink -f "${SCRIPTPATH}/../..");

source ${PROJECTPATH}/.scripts/utils.sh;
# source ./utils/ssh_utils.sh;

function CURTAIL() {  return 0; }

# echo -e "${PRTY} Preparing environment...";
# export ENV_VARS="${SCRIPTPATH}/env_vars.sh";
# export STANDARD_ENV_VARS="${SCRIPTPATH}/standard_env_vars.sh";
# export VHOST_ENV_VARS="${SCRIPTPATH}/vhost_env_vars.sh";

# source ${ENV_VARS};
# source ${STANDARD_ENV_VARS};

# declare TARGET_SCRIPTS="/utils/target";

declare RAM_DISK=/dev/shm;
declare BUILD_TARGET_DIR=${RAM_DISK}/target;
mkdir -p ${BUILD_TARGET_DIR};

# declare provisioningParmsFile=${BUILD_TARGET_DIR}/.deployParms;
declare DEPLOY_DIR=${BUILD_TARGET_DIR}/.deploy;
export ENVIRONMENT="${DEPLOY_DIR}/environment.sh";
export HOST_SCRIPTS="${DEPLOY_DIR}/host_scripts";

export APP_NAME="";
export APP_RELEASE="";

mkdir -p ${HOST_SCRIPTS};
echo "" > ${provisioningParmsFile};

function DeployBundle() {

  collectProvisioningParameters;
  collectDeploymentParameters;
  collectBuildSecrets;

  # collectProvisioningParameters ${provisioningParmsFile};
  # collectDeploymentParameters ${deploymentParmsFile};
  # collectBuildSecrets ${secretsFile};

  export ENVIRONMENT="${BUILD_TARGET_DIR}/environment.sh";
  # touch ${ENVIRONMENT};
  # cat ${ENV_VARS} ${VHOST_ENV_VARS} > ${ENVIRONMENT};

  echo -e "${PRTY}  ......  .......";

  # source ${HOME}/.userVars.sh;
  echo -e "${PRETTY} TARGET_SRVR=${TARGET_SRVR}";
  echo -e "${PRETTY} SETUP_USER_UID=${SETUP_USER_UID}";
  echo -e "${PRETTY} VHOST_SECRETS_PATH=${VHOST_SECRETS_PATH}";
  echo -e "${PRETTY} VHOST_SECRETS_FILE=${VHOST_SECRETS_FILE}";
  echo -e "${PRTY}  ......   .......";

  # source ${VHOST_SECRETS_FILE};
  # source ./specs.sh;

  echo -e "${PRTY}  ......  ${pkg_name} :: ${pkg_version}  ......";
  APP_NAME=$(jq -r .name package.json);
  APP_RELEASE=$(jq -r .version package.json);
  export COMPLETED_BUNDLE="${APP_NAME}_${APP_RELEASE}.tar.gz";


  AddSSHkeyToAgent ${DEPLOY_USER_SSH_KEY_FILE} ${DEPLOY_USER_SSH_PASS_PHRASE};

  # sudo ls >/dev/null;
set +e;
  pushd ${PROJECTPATH} &>/dev/null;

    echo -e "${PRTY} install '${APP_NAME}' project ...";

    # .scripts/preFlightCheck.sh;
    # . ${HOME}/.userVars.sh;

    if [[ -f ${BUILD_TARGET_DIR}/${COMPLETED_BUNDLE} ]]; then
      echo -e "${PRTY}

      Ram disk already holds a file '${BUILD_TARGET_DIR}/${COMPLETED_BUNDLE}'.
      Will not rebuild it.
      ";
    else
      source .scripts/android/installAndBuildTools.sh;
      echo -e "${PRTY} Preparing To Build AndroidAPK";

      installAndroid;

      PrepareToBuildAndroidAPK;

      echo -e "${PRTY} Prepared for building AndroidAPK";

      # rm -fr ./node_modules;
      # rm -fr ./.meteor/local;
      # mkdir -p ./node_modules;

      echo -e "${PRTY} Installing Node dependencies";
      meteor npm install;


      echo -e "${PRTY} Building AndroidAPK as ${APP_NAME}";
      BuildAndroidAPK;

      echo -e "${PRTY} Renaming APK.";
      pushd public/mobile/android >/dev/null;
        rm -f mmks.apk.txt;
        mv ${APP_NAME}.apk mmks.apk;
        mv ${APP_NAME}.apk.txt mmks.apk.txt;
      popd >/dev/null;

      echo -e "${PRTY} Building '${APP_NAME}' server bundle with embedded 'apk' in ${BUILD_TARGET_DIR}.";
      meteor build ${BUILD_TARGET_DIR} --server-only --directory;

    fi;

    echo -e "${PRTY} Secure CoPying '${APP_NAME}' server bundle as '${COMPLETED_BUNDLE}'.";
    pushd ${BUILD_TARGET_DIR} >/dev/null;

      tar zcvf ${COMPLETED_BUNDLE} bundle >/dev/null;
      scp ${COMPLETED_BUNDLE} ${DEPLOY_USER}@${TARGET_SRVR}:/home/${DEPLOY_USER}/MeteorApp;
      echo -e "${PRTY} Secure CoPyed '${APP_NAME}' server bundle as '${COMPLETED_BUNDLE}'.";

    popd >/dev/null;

  popd &>/dev/null;

}

function notReady() {


  declare APP_INSTALLER="InstallMeteorApp";

  pushd .${TARGET_SCRIPTS} >/dev/null;

    echo -e "${PRTY} Secure CoPying '${APP_INSTALLER}.sh' to server.";
    sh ${APP_INSTALLER}.template.sh > ${APP_INSTALLER}.sh;
    chmod a+x ${APP_INSTALLER}.sh;
    scp ${APP_INSTALLER}.sh ${DEPLOY_USER}@${TARGET_SRVR}:/home/${DEPLOY_USER}/${BUNDLE_DIRECTORY_NAME};
    rm -fr ${APP_INSTALLER}.sh;

  popd >/dev/null;

  echo -e "${PRTY} Calling :: ssh ${DEPLOY_USER}@${TARGET_SRVR} \". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/${APP_INSTALLER}.sh\";";
  # ssh ${DEPLOY_USER}@${TARGET_SRVR} ". .bash_login; nvm use --delete-prefix v4.8.3 --silent";
  ssh ${DEPLOY_USER}@${TARGET_SRVR} ". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/${APP_INSTALLER}.sh";


  echo -e "${PRTY}   All done.
  ..................................................................
  ";
}


# pushd .${TARGET_SCRIPTS} >/dev/null;
#   echo -e "Copying './postgresql/LoadBackup.sh' to server ...";
#   scp ./postgresql/LoadBackup.sh ${DEPLOY_USER}@${TARGET_SRVR}:/home/${DEPLOY_USER}/${BUNDLE_DIRECTORY_NAME}/postgresql;
#   echo -e "done ...";
# popd >/dev/null;


#   CURTAIL && (
#     echo -e "             * * *  CURTAILED * * * ";
#   ) && exit || (
#     echo -e "             * * *  NOT curtailed - Start * * * ";
#   )

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z ${1} ]]; then
    echo -e "The URL of the target virtual host is required!";
    exit;
  fi;
  export VIRTUAL_HOST_DOMAIN_NAME=${1};
  DeployBundle;
fi;
