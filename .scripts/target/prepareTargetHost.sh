#!/usr/bin/env bash
#

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

  pwd;
  echo -e "||||||||||||| C U R T A I L E D ||||||||||  ${PROJECTPATH}  |||||";
  exit;

ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l "${DEPLOY_USER}" "${TARGET_SRVR}" whoami;
echo -e "${PRETTY}Tested '${DEPLOY_USER}' user SSH to host '${TARGET_SRVR}'.";
echo -e "${PRETTY} Idempotency command throws error on first run ...";
ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.nvm/nvm.sh && nvm use --delete-prefix v4.8.3 --silent";
echo -e "${PRETTY} ... above error (if any) can be ignored.";

ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.bash_login && sudo -A touch /opt/delete_me" || exit 1;
echo -e "${PRETTY}Tested sudo ASK_PASS for '${DEPLOY_USER}'@'${TARGET_SRVR}'.";

echo -e "${PRETTY}Pushed installer scripts to host :: '${TARGET_SRVR}'.";

echo -e "






||||||||||||||||||||||||||||||||||||||||||||||";
ssh ${DEPLOY_USER}@${TARGET_SRVR} ". ~/.bash_login && ~/DeploymentPkgInstallerScripts/DeploymentPackageRunner.sh";

echo -e "||||||||||||||||||||||||||||||||||||||||||||||";
exit;
echo -e "      ** Done **

ssh ${DEPLOY_USER}@${TARGET_SRVR} \". .bash_login && sudo -A journalctl -n 1000 -fb -u ${YOUR_ORG}_${YOUR_PKG}.service\";
ssh ${DEPLOY_USER}@${TARGET_SRVR} \". .bash_login && sudo -A systemctl stop ${YOUR_ORG}_${YOUR_PKG}.service\";

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
echo -e "${PRETTY} SOURCE_CERTS_DIR : ${SOURCE_CERTS_DIR}.";
echo -e "${PRETTY} VHOST_SUBJECT : ${VHOST_SUBJECT}.";
echo -e "${PRETTY} VHOST_CERT_PASSPHRASE : ${VHOST_CERT_PASSPHRASE}.";
echo -e "${PRETTY}  : ${PRETTY}.";
# echo -e "${PRETTY} METEOR_SETTINGS_FILE : ${METEOR_SETTINGS_FILE}.";
echo -e "${PRETTY} VHOST_ENV_VARS : ${VHOST_ENV_VARS}.";
echo -e "${PRETTY} TARGET_SRVR : ${TARGET_SRVR}.";
echo -e "${PRETTY} VIRTUAL_HOST_DOMAIN_NAME : ${VIRTUAL_HOST_DOMAIN_NAME}.";
echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_PATH : ${DEPLOY_USER_SSH_KEY_PATH}.";
echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_COMMENT : ${DEPLOY_USER_SSH_KEY_COMMENT}.";
echo -e "${PRETTY} DEPLOY_USER_SSH_PASS_PHRASE : ${DEPLOY_USER_SSH_PASS_PHRASE}.";
echo -e "${PRETTY} DEPLOY_USER_SSH_KEY_FILE : ${DEPLOY_USER_SSH_KEY_FILE}.";
echo -e "${PRETTY} DEPLOY_USER : ${DEPLOY_USER}.";
echo -e "${PRETTY} VHOST_SECRETS_FILE : ${VHOST_SECRETS_FILE}.";
echo -e "${PRETTY} YOUR_TARGET_SRVR_SSH_KEY_FILE : ${YOUR_TARGET_SRVR_SSH_KEY_FILE}.";
echo -e "${PRETTY} SETUP_USER_UID : ${SETUP_USER_UID}.";
echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";


};

function collectDeploymentParameters() {

  cp ${PROJECTPATH}/sample_settings.json ${PROJECTPATH}/settings.json;
  echo -e "ENVIRONMENT => ${ENVIRONMENT}";
  echo -e "#!/usr/bin/env bash\n# Target server env vars" > ${ENVIRONMENT};

  getParmFromJSON ".deploymentParametersIndexFile"  "PARMSFILE" "settings.json";
  echo "PARMSFILE => ${PARMSFILE}" ;
  getParmFromJSON ".standard.SSH_PATH" "SSH_PATH" "${PARMSFILE}";
  echo "SSH_PATH => ${SSH_PATH}";
  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].TARGET_SRVR" "TARGET_SRVR" "${PARMSFILE}";
  echo "TARGET_SRVR => ${TARGET_SRVR}";
  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].adminUser.DEPLOY_USER" "DEPLOY_USER" "${PARMSFILE}";
  echo "DEPLOY_USER => ${DEPLOY_USER}";
  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].adminUser.DEPLOY_USER_SSH_KEY_COMMENT" "DEPLOY_USER_SSH_KEY_COMMENT" "${PARMSFILE}";
  echo "DEPLOY_USER_SSH_KEY_COMMENT => ${DEPLOY_USER_SSH_KEY_COMMENT}";
  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].SETUP_USER_UID" "SETUP_USER_UID" "${PARMSFILE}";
  echo "SETUP_USER_UID => ${SETUP_USER_UID}";

  getParmFromJSON ".standard.SECRETS_PATH" "SECRETS_PATH" "${PARMSFILE}";
  echo "SECRETS_PATH => ${SECRETS_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SECRETS_DIR" "DEPLOY_USER_SECRETS_DIR" "${PARMSFILE}";
  echo "DEPLOY_USER_SECRETS_DIR => ${DEPLOY_USER_SECRETS_DIR}";

  getParmFromJSON ".standard.VHOST_SECRETS_PATH" "VHOST_SECRETS_PATH" "${PARMSFILE}";
  echo "VHOST_SECRETS_PATH => ${VHOST_SECRETS_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SECRETS_PATH" "DEPLOY_USER_SECRETS_PATH" "${PARMSFILE}";
  echo "DEPLOY_USER_SECRETS_PATH => ${DEPLOY_USER_SECRETS_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PATH" "DEPLOY_USER_SSH_KEY_PATH" "${PARMSFILE}";
  echo "DEPLOY_USER_SSH_KEY_PATH => ${DEPLOY_USER_SSH_KEY_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_FILE" "DEPLOY_USER_SSH_KEY_FILE" "${PARMSFILE}";
  echo "DEPLOY_USER_SSH_KEY_FILE => ${DEPLOY_USER_SSH_KEY_FILE}";

  getParmFromJSON ".standard.VHOST_SECRETS_FILE" "VHOST_SECRETS_FILE" "${PARMSFILE}";
  echo "VHOST_SECRETS_FILE => ${VHOST_SECRETS_FILE}";

  getParmFromJSON ".standard.YOUR_TARGET_SRVR_SSH_KEY_FILE" "YOUR_TARGET_SRVR_SSH_KEY_FILE" "${PARMSFILE}";
  echo "YOUR_TARGET_SRVR_SSH_KEY_FILE => ${YOUR_TARGET_SRVR_SSH_KEY_FILE}";

  getParmFromJSON ".DEPLOY_USER_SSH_PASS_PHRASE" "DEPLOY_USER_SSH_PASS_PHRASE" "${VHOST_SECRETS_FILE}";
  echo "DEPLOY_USER_SSH_PASS_PHRASE => ${DEPLOY_USER_SSH_PASS_PHRASE}";

  getParmFromJSON ".standard.SSH_CONF_FILE" "SSH_CONF_FILE" "${PARMSFILE}";
  echo "SSH_CONF_FILE => ${SSH_CONF_FILE}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PUBL" "DEPLOY_USER_SSH_KEY_PUBL" "${PARMSFILE}";
  echo "DEPLOY_USER_SSH_KEY_PUBL => ${DEPLOY_USER_SSH_KEY_PUBL}";


   echo -e "----
       ${DEPLOY_USER_SSH_KEY_COMMENT}
       ${DEPLOY_USER_SSH_PASS_PHRASE}
       ${DEPLOY_USER_SSH_KEY_PATH}
       ${DEPLOY_USER_SSH_KEY_FILE}
     -----";

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
  declare deployParmsFile=${WORKDIR}/.deployParms;
  declare DEPLOY_DIR=${WORKDIR}/.deploy;
  export ENVIRONMENT="${DEPLOY_DIR}/environment.sh";
  export HOST_SCRIPTS="${DEPLOY_DIR}/host_scripts";

  mkdir -p ${HOST_SCRIPTS};
  echo "" > ${deployParmsFile};

  collectDeploymentParameters ${deployParmsFile};


  cp ${PARMSFILE} ${deployParmsFile};
  cp .scripts/target/PushInstallerScriptsToTarget.sh ${DEPLOY_DIR};
  cp .scripts/target/host_scripts ${DEPLOY_DIR};

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
