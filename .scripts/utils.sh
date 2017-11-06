#!/usr/bin/env bash
#

function makeSSH_Config_File() {

  mkdir -p ${SSH_PATH};
  touch ${SSH_CONF_FILE};
  cp ${SSH_CONF_FILE} ${SSH_CONF_FILE}_BK &>/dev/null;
  chmod ugo-w ${SSH_CONF_FILE}_BK;

}

function addSSH_Config_Identity() {
  USER_ID=${1};
  SRVR=${2};
  SSH_KEY_FILE=${3};

  export PTRN="# ${USER_ID} account on ${SRVR}";
  export PTRNB="${PTRN} «begins»";
  export PTRNE="${PTRN} «ends»";
  #
  sed -i "/${PTRNB}/,/${PTRNE}/d" ${SSH_CONF_FILE};
  #
echo -e "${PTRNB}
Host ${SRVR}
    HostName ${SRVR}
    User ${USER_ID}
    PreferredAuthentications publickey
    IdentityFile ${SSH_KEY_FILE}
${PTRNE}
" >> ${SSH_CONF_FILE}

  sed -i "s/ *$//" ${SSH_CONF_FILE}; # trim whitespace to EOL
  sed -i "/^$/N;/^\n$/D" ${SSH_CONF_FILE}; # blank lines to 1 line
}

function AddSSHkeyToAgent() {

  local KEY_FILE="${1}";
  local PASS_PHRASE="${2}";

  # echo "PASS_PHRASE = '${PASS_PHRASE}', KEY_FILE = '${KEY_FILE}'";

  local KEY_PRESENT=$(ssh-add -l | grep -c ${KEY_FILE});
  if [[ "${KEY_PRESENT}" -gt "0" ]]; then
    return 1;
  elif [[ -f ${KEY_FILE} ]]; then
    echo -e "${PRETTY} Remembering SSH key: '${KEY_FILE}'...";
    startSSHAgent;
    expect << EOF
      spawn ssh-add ${KEY_FILE}
      expect "Enter passphrase"
      send -- "${PASS_PHRASE}\r"
      expect eof
EOF
  else
    return 1;
  fi;

};

function makeTargetAuthorizedHostSshKeyIfNotExist() {

  COMMENT="${1}";
  PASS_PHRASE="${2}";
  KEY_PATH="${3}";  # HABITAT_USER_SSH_KEY_PATH
  KEY_FILE="${4}";  # HABITAT_USER_SSH_KEY_FILE

  # echo -e "COMMENT = '${COMMENT}', \nPASS_PHRASE = '${PASS_PHRASE}'";
  # echo -e "KEY_PATH = '${KEY_PATH}', \nKEY_FILE = '${KEY_FILE}'";

  mkdir -p ${KEY_PATH};

  if [[ -f ${KEY_FILE} && -f ${KEY_FILE}.pub ]]; then
    echo -e "${PRETTY}Target server 'authorized_host' key pair already exists.";
  else
    echo -e "${PRETTY}Target server 'authorized_host' key pair not found.  Creating now.";
    rm -f ${KEY_FILE}*;
    ssh-keygen \
      -t rsa \
      -C "${COMMENT}" \
      -f "${KEY_FILE}" \
      -P "${PASS_PHRASE}" \
      && cat ${KEY_FILE}.pub;
    chmod go-rwx ${KEY_FILE};
    chmod go-wx ${KEY_FILE}.pub;
    chmod go-w ${KEY_PATH};
  fi;
  echo -e "  -- keys are here : '${KEY_PATH}'.";

}

function getParmFromJSON() {
  declare PARM=${1};
  declare RETURN_VAR=${2};
  declare PARMS_FILE_PATH=${3};
  declare RESULT=$(jq ${PARM} -rMc ${PARMS_FILE_PATH});
  # declare RSLT=$(jq ${PARM} -rMc ${PARMS_FILE_PATH});
  # declare RESULT=$(eval echo ${RSLT})
  # echo -e "
  # RSLT  => ${RSLT}
  # RESULT  => ${RESULT}";
                # echo "export ${RETURN_VAR}=\$(jq ${PARM} -rMc ${PARMS_FILE_PATH})";
              #  eval "export ${RETURN_VAR}=$(jq ${PARM} -rMc ${PARMS_FILE_PATH})";
  # echo "export ${RETURN_VAR}=\"${RESULT}\"";
  eval "export ${RETURN_VAR}=\"${RESULT}\"";
}


function collectProvisioningParameters() {

  cp ${PROJECTPATH}/sample_settings.json ${PROJECTPATH}/settings.json;
  echo -e "# Target server provisioning env vars" >> ${ENVIRONMENT};

  getParmFromJSON ".deploymentParametersIndexFile"  "PARMSFILE" "settings.json";
  echo "export PARMSFILE=${PARMSFILE}" ;

  getParmFromJSON ".name"  "APP_NAME" "package.json";
  echo "export APP_NAME=${APP_NAME}" ;

  getParmFromJSON ".version"  "PKG_VERSION" "package.json";
  echo "export PKG_VERSION=${PKG_VERSION}" ;

  getParmFromJSON ".applications[\"${APP_NAME}\"].METEOR_NODE_VERSION" "METEOR_NODE_VERSION" "${PARMSFILE}";
  echo "export METEOR_NODE_VERSION='${METEOR_NODE_VERSION}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".standard.SSH_PATH" "SSH_PATH" "${PARMSFILE}";
  echo "export SSH_PATH=${SSH_PATH}";

  getParmFromJSON ".standard.BUNDLE_DIRECTORY_NAME" "BUNDLE_DIRECTORY_NAME" "${PARMSFILE}";
  echo "export BUNDLE_DIRECTORY_NAME=${BUNDLE_DIRECTORY_NAME}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].TARGET_SRVR" "TARGET_SRVR" "${PARMSFILE}";
  echo "export TARGET_SRVR=${TARGET_SRVR}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].adminUser.DEPLOY_USER" "DEPLOY_USER" "${PARMSFILE}";
  echo "export DEPLOY_USER='${DEPLOY_USER}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].RDBMS_ROLE" "RDBMS_ROLE" "${PARMSFILE}";
  echo "export RDBMS_ROLE='${RDBMS_ROLE}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].adminUser.DEPLOY_USER_SSH_KEY_COMMENT" "DEPLOY_USER_SSH_KEY_COMMENT" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_COMMENT=${DEPLOY_USER_SSH_KEY_COMMENT}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].SETUP_USER_UID" "SETUP_USER_UID" "${PARMSFILE}";
  echo "export SETUP_USER_UID=${SETUP_USER_UID}";

  getParmFromJSON ".standard.SECRETS_PATH" "SECRETS_PATH" "${PARMSFILE}";
  echo "export SECRETS_PATH=${SECRETS_PATH}";

  getParmFromJSON ".standard.APP_DIRECTORY_NAME" "APP_DIRECTORY_NAME" "${PARMSFILE}";
  echo "export APP_DIRECTORY_NAME='${APP_DIRECTORY_NAME}';" | tee -a ${ENVIRONMENT}

  getParmFromJSON ".standard.DEPLOY_USER_SECRETS_DIR" "DEPLOY_USER_SECRETS_DIR" "${PARMSFILE}";
  echo "export DEPLOY_USER_SECRETS_DIR=${DEPLOY_USER_SECRETS_DIR}";

  getParmFromJSON ".standard.VHOST_SECRETS_PATH" "VHOST_SECRETS_PATH" "${PARMSFILE}";
  echo "export VHOST_SECRETS_PATH=${VHOST_SECRETS_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SECRETS_PATH" "DEPLOY_USER_SECRETS_PATH" "${PARMSFILE}";
  echo "export DEPLOY_USER_SECRETS_PATH=${DEPLOY_USER_SECRETS_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PATH" "DEPLOY_USER_SSH_KEY_PATH" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_PATH=${DEPLOY_USER_SSH_KEY_PATH}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_FILE" "DEPLOY_USER_SSH_KEY_FILE" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_FILE=${DEPLOY_USER_SSH_KEY_FILE}";

  getParmFromJSON ".standard.VHOST_SECRETS_FILE" "VHOST_SECRETS_FILE" "${PARMSFILE}";
  echo "export VHOST_SECRETS_FILE=${VHOST_SECRETS_FILE}";

  getParmFromJSON ".standard.YOUR_TARGET_SRVR_SSH_KEY_FILE" "YOUR_TARGET_SRVR_SSH_KEY_FILE" "${PARMSFILE}";
  echo "export YOUR_TARGET_SRVR_SSH_KEY_FILE=${YOUR_TARGET_SRVR_SSH_KEY_FILE}";

  export HOST_SERVER_NAME="${VIRTUAL_HOST_DOMAIN_NAME}";
  echo "export VIRTUAL_HOST_DOMAIN_NAME='${VIRTUAL_HOST_DOMAIN_NAME}';" | tee -a ${ENVIRONMENT};

  export SECRETS="secrets.sh";
  echo "export SECRETS='${SECRETS}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".DEPLOY_USER_SSH_PASS_PHRASE" "DEPLOY_USER_SSH_PASS_PHRASE" "${VHOST_SECRETS_FILE}";
  echo "export DEPLOY_USER_SSH_PASS_PHRASE=${DEPLOY_USER_SSH_PASS_PHRASE}";

  getParmFromJSON ".SETUP_USER_PWD" "SETUP_USER_PWD" "${VHOST_SECRETS_FILE}";
  echo "export SETUP_USER_PWD=${SETUP_USER_PWD}";

  getParmFromJSON ".DEPLOY_USER_PWD" "DEPLOY_USER_PWD" "${VHOST_SECRETS_FILE}";
  echo "export DEPLOY_USER_PWD=${DEPLOY_USER_PWD}";

  getParmFromJSON ".NOSQLDB_PWD" "NOSQLDB_PWD" "${VHOST_SECRETS_FILE}";
  echo "export NOSQLDB_PWD=${NOSQLDB_PWD}";

  getParmFromJSON ".RDBMS_PWD" "RDBMS_PWD" "${VHOST_SECRETS_FILE}";
  echo "export RDBMS_PWD=${RDBMS_PWD}";

  getParmFromJSON ".RDBMS_ADMIN_PWD" "RDBMS_ADMIN_PWD" "${VHOST_SECRETS_FILE}";
  echo "export RDBMS_ADMIN_PWD=${RDBMS_ADMIN_PWD}";

  getParmFromJSON ".NOSQLDB_ADMIN_PWD" "NOSQLDB_ADMIN_PWD" "${VHOST_SECRETS_FILE}";
  echo "export NOSQLDB_ADMIN_PWD=${NOSQLDB_ADMIN_PWD}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].accounts.GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_ID" "${PARMSFILE}";
  echo "export GOOGLE_CLIENT_ID='${GOOGLE_CLIENT_ID}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".GOOGLE_CLIENT_SECRET" "GOOGLE_CLIENT_SECRET" "${VHOST_SECRETS_FILE}";
  echo "export GOOGLE_CLIENT_SECRET='${GOOGLE_CLIENT_SECRET}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].accounts.TWITTER_CONSUMER_KEY" "TWITTER_CONSUMER_KEY" "${PARMSFILE}";
  echo "export TWITTER_CONSUMER_KEY='${TWITTER_CONSUMER_KEY}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".TWITTER_SECRET" "TWITTER_SECRET" "${VHOST_SECRETS_FILE}";
  echo "export TWITTER_SECRET='${TWITTER_SECRET}';" | tee -a ${ENVIRONMENT};


  getParmFromJSON ".standard.SSH_CONF_FILE" "SSH_CONF_FILE" "${PARMSFILE}";
  echo "export SSH_CONF_FILE=${SSH_CONF_FILE}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PUBL" "DEPLOY_USER_SSH_KEY_PUBL" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_PUBL=${DEPLOY_USER_SSH_KEY_PUBL}";

  getParmFromJSON ".standard.METEOR_NODE_APP_PATH" "METEOR_NODE_APP_PATH" "${PARMSFILE}";
  echo "export METEOR_NODE_APP_PATH='${METEOR_NODE_APP_PATH}';" | tee -a ${ENVIRONMENT};


  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_HST" "RDBMS_HST" "${PARMSFILE}";
  echo "export RDBMS_HST='${RDBMS_HST}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_DIALECT" "RDBMS_DIALECT" "${PARMSFILE}";
  echo "export RDBMS_DIALECT='${RDBMS_DIALECT}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_PORT" "RDBMS_PORT" "${PARMSFILE}";
  echo "export RDBMS_PORT='${RDBMS_PORT}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_DB" "RDBMS_DB" "${PARMSFILE}";
  echo "export RDBMS_DB='${RDBMS_DB}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_ROLE" "RDBMS_ROLE" "${PARMSFILE}";
  echo "export RDBMS_ROLE='${RDBMS_ROLE}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_OWNER" "RDBMS_OWNER" "${PARMSFILE}";
  echo "export RDBMS_OWNER='${RDBMS_OWNER}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_UID" "RDBMS_UID" "${PARMSFILE}";
  echo "export RDBMS_UID='${RDBMS_UID}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].sql.RDBMS_BKP" "RDBMS_BKP" "${PARMSFILE}";
  echo "export RDBMS_BKP='${RDBMS_BKP}';" | tee -a ${ENVIRONMENT};



  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].no_sql.NOSQLDB_HST" "NOSQLDB_HST" "${PARMSFILE}";
  echo "export NOSQLDB_HST='${NOSQLDB_HST}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].no_sql.NOSQLDB_DIALECT" "NOSQLDB_DIALECT" "${PARMSFILE}";
  echo "export NOSQLDB_DIALECT='${NOSQLDB_DIALECT}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].no_sql.NOSQLDB_PORT" "NOSQLDB_PORT" "${PARMSFILE}";
  echo "export NOSQLDB_PORT='${NOSQLDB_PORT}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].no_sql.NOSQLDB_DB" "NOSQLDB_DB" "${PARMSFILE}";
  echo "export NOSQLDB_DB='${NOSQLDB_DB}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].no_sql.NOSQLDB_UID" "NOSQLDB_UID" "${PARMSFILE}";
  echo "export NOSQLDB_UID='${NOSQLDB_UID}';" | tee -a ${ENVIRONMENT};


};



function collectDeploymentParameters() {

  echo -e "\n#\n# Target server deployment parameters" >> ${ENVIRONMENT};

  getParmFromJSON ".deploymentParametersIndexFile"  "PARMSFILE" "settings.json";
  echo "export PARMSFILE=${PARMSFILE}" ;

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PUBL" "DEPLOY_USER_SSH_KEY_PUBL" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_PUBL=${DEPLOY_USER_SSH_KEY_PUBL}";

  getParmFromJSON ".standard.DEPLOY_USER_SSH_KEY_PUBL" "DEPLOY_USER_SSH_KEY_PUBL" "${PARMSFILE}";
  echo "export DEPLOY_USER_SSH_KEY_PUBL=${DEPLOY_USER_SSH_KEY_PUBL}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].YOUR_FULLNAME" "YOUR_FULLNAME" "${PARMSFILE}";
  echo "export YOUR_FULLNAME=${YOUR_FULLNAME}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].YOUR_ORGANIZATION_NAME" "YOUR_ORGANIZATION_NAME" "${PARMSFILE}";
  echo "export YOUR_ORGANIZATION_NAME=${YOUR_ORGANIZATION_NAME}";

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].protocol.HOST_SERVER_PROTOCOL" "HOST_SERVER_PROTOCOL" "${PARMSFILE}";
  echo "export HOST_SERVER_PROTOCOL='${HOST_SERVER_PROTOCOL}';" | tee -a ${ENVIRONMENT};

  getParmFromJSON ".virtual_hosts[\"${VIRTUAL_HOST_DOMAIN_NAME}\"].protocol.HOST_SERVER_PORT" "HOST_SERVER_PORT" "${PARMSFILE}";
  echo "export HOST_SERVER_PORT='${HOST_SERVER_PORT}';" | tee -a ${ENVIRONMENT};



};


function collectBuildSecrets() {

  getParmFromJSON ".KEYSTORE_PWD" "KEYSTORE_PWD" "${VHOST_SECRETS_FILE}";
  echo "export KEYSTORE_PWD=${KEYSTORE_PWD}";

};


function startSSHAgent() {
  echo -e "${PRTY} Starting 'ssh-agent' ...";
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s);
    echo -e "${PRTY} Started 'ssh-agent' ...";
  fi;
};

function UpdateEnvVars() {

  local ENV_FILE=$1;
  local ENV_NAME=$2;
  local ENV_VAL=$3;
  local ENV_FILE_NAME=$(basename ${ENV_FILE});

  [ -f "${ENV_FILE}" ] || touch ${ENV_FILE};
  echo -e "Correcting ${ENV_NAME} in '${ENV_FILE}' variables.";

  if [[ $(grep -c "export ${ENV_NAME}=${ANDROID_HOME}"  ${ENV_FILE}) -lt 1 ]]; then
    while [[ $(grep -c ${ENV_NAME} ${ENV_FILE}) -gt 0 ]]; do
      sed -i "/${ENV_NAME}/d" ${ENV_FILE};
    done;
    echo -e "\nexport ${ENV_NAME}=${ENV_VAL};\n" | tee -a ${ENV_FILE};
  fi;

  cat ${ENV_FILE} | uniq > /dev/shm/${ENV_FILE_NAME};
  mv /dev/shm/${ENV_FILE_NAME} ${ENV_FILE};

}

# [ -z $(jq --version &>/dev/null ) ] && sudo apt -y install jq # || echo "found jq version «$(jq --version)»";
# function GetProjectName() {

#   local JSON_FILE=$1;
#   echo -e "Extracting project name from : ${JSON_FILE}.";
#   APP_NAME=$( jq '.name' ${JSON_FILE} | sed 's/"//g' );

# }

# function validateMeteorSettings() {

#   if [[ "null" = "${HOST_SERVER_NAME}" || -z "${HOST_SERVER_NAME}" ]]; then
#     echo -e "
#      The environment variable 'HOST_SERVER_NAME' is undefined!
#          Secret settings under ...
#             '/home/$(whoami)/.ssh/deploy_vault/\${HOST_SERVER_NAME}/secrets.sh;'
#                 ... could not be read.
#     ";
#     exit 1;
#   fi;

#   declare SECRETS_FILE="${HOME}/.ssh/deploy_vault/${HOST_SERVER_NAME}/secrets.sh";
#   echo -e "${PRTY} Verify 'settings.json' or generate from ${SECRETS_FILE}";
#   if [[ "${CI}" = "true" ]]; then
#     echo -e "Running in Continuous Integration server environment. 'secrets.sh' was NOT loaded";
#     ./template.settings.json.sh > settings.json;
#   else
#     # echo "B";
#     if [ ! -f settings.json ]; then
#     # echo "C";
#       if [ -f ${SECRETS_FILE} ]; then
#     # echo "D";
#         source ${SECRETS_FILE};
#         ./template.settings.json.sh > settings.json;
#       else
#         echo -e "
#         Your secret settings were not found at :

#              ${SECRETS_FILE};\n";
#         exit 1;
#       fi;
#     # echo "E";
#     fi;
#     # cat settings.json;
#     # echo "F";
#   fi;

#   if [ -f settings.json ]; then
#     LG_DOM=$(jq -r .LOGGLY_SUBDOMAIN settings.json);
#     # echo ${LG_DOM};
#     if [[ -z ${LG_DOM} || "${LG_DOM}" = "null" ]]; then
#       echo -e "
#       Your secret settings file, '${SECRETS_FILE}', is incomplete.
#       'LOGGLY_SUBDOMAIN' is required\n";
#       # cat ${SECRETS_FILE};
#       exit 1;
#     fi;
#     echo -e "Result : ";
#     grep "LOGGLY_SUBDOMAIN" settings.json;
#   fi;



# }

# function haveUtils() {
#   echo -e "Yes.  We sourced 'utils.js'";
# }