#!/usr/bin/env bash
#
declare PRTY="~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nYourPublic App :: Prep Srvr :: ";

declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");  # Where this script resides
declare SCRIPTNAME=$(basename "$SCRIPT"); # This script's name
declare PROJECTPATH=$(readlink -f "${SCRIPTPATH}/../..");

source ${PROJECTPATH}/.scripts/utils.sh;

function setupTargetServer() {

  startSSHAgent;

   echo -e "----
   ${DEPLOY_USER_SSH_KEY_COMMENT}
       ${DEPLOY_USER_SSH_PASS_PHRASE}
       ${DEPLOY_USER_SSH_KEY_PATH}
       ${DEPLOY_USER_SSH_KEY_FILE}
     -----";

  makeTargetAuthorizedHostSshKeyIfNotExist \
       "${DEPLOY_USER_SSH_KEY_COMMENT}" \
       "${DEPLOY_USER_SSH_PASS_PHRASE}" \
       "${DEPLOY_USER_SSH_KEY_PATH}" \
       "${DEPLOY_USER_SSH_KEY_FILE}";

  AddSSHkeyToAgent "${DEPLOY_USER_SSH_KEY_FILE}" "${DEPLOY_USER_SSH_PASS_PHRASE}";

  # [ -z ${QUICK} ] && chkHostConn;

  # ....
  makeSSH_Config_File;
  addSSH_Config_Identity "${SETUP_USER_UID}" "${TARGET_SRVR}" "${YOUR_TARGET_SRVR_SSH_KEY_FILE}";
  addSSH_Config_Identity "${DEPLOY_USER}" "${TARGET_SRVR}" "${DEPLOY_USER_SSH_KEY_FILE}";
  echo -e "${PRETTY}SSH config file prepared.";

  [ -z ${QUICK} ] && (
      echo -e "${PRETTY}Testing SSH to target : '${SETUP_USER_UID}@${TARGET_SRVR}'."
      ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l "${SETUP_USER_UID}" "${TARGET_SRVR}" whoami || exit 1;
      echo -e "${PRETTY}Success: SSH to host '${SETUP_USER_UID}' '${TARGET_SRVR}'.";
  );

  echo -e "${PRETTY} TARGET_SRVR=${TARGET_SRVR}";
  echo -e "${PRETTY} SETUP_USER_UID=${SETUP_USER_UID}";
  echo -e "${PRETTY} VHOST_SECRETS_PATH=${VHOST_SECRETS_PATH}";
  echo -e "${PRETTY} ENVIRONMENT=${ENVIRONMENT}";

  echo -e "${PRETTY} VHOST_SECRETS_FILE=${VHOST_SECRETS_FILE}";
  echo -e "${PRETTY} VHOST_ENV_VARS=${VHOST_ENV_VARS}";


  .deploy/PushInstallerScriptsToTarget.sh \
    "${TARGET_SRVR}" \
    "${SETUP_USER_UID}" \
    "${VHOST_SECRETS_PATH}" \
    "${ENVIRONMENT}";

echo -e "${PRETTY}Tested '${DEPLOY_USER}' user SSH to host '${TARGET_SRVR}'.";
echo -e "${PRETTY} Idempotency command throws error on first run ...";
ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.nvm/nvm.sh && nvm use --delete-prefix v4.8.3 --silent";
echo -e "${PRETTY} ... above error (if any) can be ignored.";

ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.bash_login && sudo -A touch /opt/delete_me" || exit 1;
echo -e "${PRETTY}Tested sudo ASK_PASS for '${DEPLOY_USER}'@'${TARGET_SRVR}'.";

echo -e "${PRETTY}Pushed installer scripts to host :: '${TARGET_SRVR}'.";

echo -e "





||||||||||||||||||||||||||||||||||||||||||||||";
# ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.bash_login && ~/DeploymentPkgInstallerScripts/DeploymentPackageRunner.sh";

echo -e "      ** Done **

ssh ${DEPLOY_USER}@${TARGET_SRVR} \". .bash_login && sudo -A journalctl -n 1000 -fb\";
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
exit;

# echo -e "${PRETTY} SOURCE_CERTS_DIR : ${SOURCE_CERTS_DIR}.";
# echo -e "${PRETTY} VHOST_SUBJECT : ${VHOST_SUBJECT}.";
# echo -e "${PRETTY} VHOST_CERT_PASSPHRASE : ${VHOST_CERT_PASSPHRASE}.";
# echo -e "${PRETTY}  : ${PRETTY}.";
# # echo -e "${PRETTY} METEOR_SETTINGS_FILE : ${METEOR_SETTINGS_FILE}.";
# echo -e "${PRETTY} VHOST_ENV_VARS : ${VHOST_ENV_VARS}.";
# echo -e "${PRETTY} TARGET_SRVR : ${TARGET_SRVR}.";
# echo -e "${PRETTY} VIRTUAL_HOST_DOMAIN_NAME : ${VIRTUAL_HOST_DOMAIN_NAME}.";
# echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_PATH : ${DEPLOY_USER_SSH_KEY_PATH}.";
# echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_COMMENT : ${DEPLOY_USER_SSH_KEY_COMMENT}.";
# echo -e "${PRETTY} DEPLOY_USER_SSH_PASS_PHRASE : ${DEPLOY_USER_SSH_PASS_PHRASE}.";
# echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_FILE : ${DEPLOY_USER_SSH_KEY_FILE}.";
# echo -e "${PRETTY} DEPLOY_USER : ${DEPLOY_USER}.";
# echo -e "${PRETTY} VHOST_SECRETS_FILE : ${VHOST_SECRETS_FILE}.";
# echo -e "${PRETTY} YOUR_TARGET_SRVR_SSH_KEY_FILE : ${YOUR_TARGET_SRVR_SSH_KEY_FILE}.";
# echo -e "${PRETTY} SETUP_USER_UID : ${SETUP_USER_UID}.";
# echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";


};

function installAptPackages() {

  echo -e "${PRETTY} Ensuring we can 'expect' log in sequences ...";
  dpkg -s expect >/dev/null || sudo apt install -y expect;

  echo -e "${PRETTY} Ensuring we can parse JSON with 'jq' ...";
  dpkg -s jq >/dev/null || sudo apt install -y jq;

};

export deploymentParameters="";
function PrepareServer () {

  installAptPackages;

  export WORKDIR="/dev/shm/inst";
  declare provisioningParmsFile=${WORKDIR}/.deployParms;
  declare DEPLOY_DIR=${WORKDIR}/.deploy;
  export ENVIRONMENT="${DEPLOY_DIR}/environment.sh";
  export HOST_SCRIPTS="${DEPLOY_DIR}/host_scripts";

  mkdir -p ${HOST_SCRIPTS};

  echo -e "provisioningParmsFile => ${provisioningParmsFile}";
  echo -e "#!/usr/bin/env bash\n# Provisioning parameters" > ${provisioningParmsFile};

  echo -e "ENVIRONMENT => ${ENVIRONMENT}";
  echo -e "#!/usr/bin/env bash" > ${ENVIRONMENT};

  collectProvisioningParameters ${provisioningParmsFile};


  cp ${PARMSFILE} ${provisioningParmsFile};
  cp .scripts/target/PushInstallerScriptsToTarget.sh ${DEPLOY_DIR};
  cp -r .scripts/target/host_scripts ${DEPLOY_DIR};


  pushd ${WORKDIR} &>/dev/null;

   setupTargetServer;

  popd &>/dev/null;

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z ${1} ]]; then
    echo -e "The URL of the target virtual host is required!";
    exit;
  fi;
  export VIRTUAL_HOST_DOMAIN_NAME=${1};
  PrepareServer;
fi;

# echo -e "||||||||||||| C U R T A I L E D |||||||||||||||||||||";
exit;
