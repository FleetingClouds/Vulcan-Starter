#!/usr/bin/env bash
#
function usage() {
  echo -e "    Usage ::
     ${SCRIPTPATH}/PushInstallerScriptsToTarget.sh \\
                   \${TARGET_SRVR} \\
                   \${SETUP_USER_UID} \\
                   \${SOURCE_SECRETS_DIR} \\
                   \${ENVIRONMENT}
      Where :
        TARGET_SRVR is the host where the project will be installed.
        SETUP_USER_UID is a previously prepared 'sudoer' account on '\${TARGET_SRVR}'.
        SOURCE_SECRETS_DIR is the path of a directory of secrets for the '\${TARGET_SRVR}' server.
            ( example : ${HOME}/.ssh/deploy_vault/\${TARGET_SRVR} )
        ENVIRONMENT is the path to a file of environment variables for '\${TARGET_SRVR}'

  ";
  exit 1;
}
#                    \${METEOR_SETTINGS_FILE} \\
#         METEOR_SETTINGS_FILE typically called 'settings.json', contains your app's internal settings,

function errorInvalidReleaseTag() {
  echo -e "\n\n    *** Invalid release tag ***";
  usage;
}

function errorCannotPingRemoteServer() {
  echo -e "\n\n    *** Cannot ping remote server : '${1}' ***";
  usage;
}

function errorNoUserAccountSpecified() {
  echo -e "\n\n    *** The user account for the remote server needs to be specified  ***";
  usage;
}

# FIXME : We should be pushing the secrets file, and making settings.json from its template
#
# function errorNoSettingsFileSpecified() {
#   echo -e "\n\n    *** A valid path to a Meteor settings.json file needs to be specified, not '${1}'  ***";
#   usage;
# }

# function warningEmptySettingsFileSpecified() {
#   echo -e "\n\n    *** An empty Meteor settings.json file was detected at, '${1}'  ***

#   ";
#   read -ep "Do you wish to (q)uit or fix that and (c)ontinue? (q/c) ::  " -n 1 -r USER_ANSWER
#   CHOICE=$(echo ${USER_ANSWER:0:1} | tr '[:upper:]' '[:lower:]')
#   if [[ "X${CHOICE}X" == "XqX" ]]; then
#     echo "Skipping this operation."; exit 1;
#   fi;
#   echo -e " Continuing... ";
# }


function errorNoSecretsDirSpecified() {
  echo -e "\n\n    *** A valid path of a directory of secrets for the remote server needs to be specified, not '${1}'  ***";
  usage;
}

function errorNoEnvVarsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of environment variables for the remote server needs to be specified, not '${1}'  ***";
  usage;
}

function errorDHParamsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of Diffie-Hellman paramaters for the remote server needs to be specified, not '${1}'  ***";
  usage;
}


function errorCannotCallRemoteProcedure() {
  echo -e "\n\n    *** Cannot call remote procedure. Is '${1}' correct? ***";
  usage;
}

function errorBadPathToSSHKey() {
  echo -e "\n\n    *** No valid SSH key found at '${1}' ***";
  usage;
}

function errorUnexpectedRPCResult() {
  echo -e "\n\n    *** Remote procedure call could not complete ***";
  usage;
}

function errorFailedToPushBundle() {
  echo -e "\n\n    *** Secure CoPy could not push bundle to remote user account ***";
  usage;
}

function errorUnsuitablePassword() {
  echo -e "\n\n    *** '${1}' is not a viable password***
                   -- Minimum size is ${PASSWORD_MINIMUM_LENGTH} chars --";
  usage;
}

function errorNoSuitablePasswordInFile() {
  echo -e "\n\n    *** No viable password found in the file, '${1}' ***
                   -- Minimum size is ${PASSWORD_MINIMUM_LENGTH} chars --";
  usage;
}

function startSSHAgent() {
  echo -e "${PRTY} Starting 'ssh-agent' ...";
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s);
    echo -e "${PRTY} Started 'ssh-agent' ...";
  fi;
};


function sourceSemVerToolkit() {

#  loadSemVerScript;
  echo -e "${PRTY} Sourcing Semantic Versioning toolkit."
  . ./semver_shell/semver.sh;

};


declare MKR_SCRPT="";
function makeMakerScriptMaker() {
  cat <<SAPMF
#!/usr/bin/env bash
#
export SUPWD="\${HOME}/.ssh/.supwd.sh";
echo -e '#!/usr/bin/env bash' > \${SUPWD};
echo -e "echo '${1}';" >> \${SUPWD};
chmod a+x,go-rwx \${SUPWD};
echo "Created ${SUPWD}";
SAPMF
}

set -e;

CURR_DIR=$(pwd);
SCRIPT=$(readlink -f "$0");
SCRIPTPATH=$(dirname "$SCRIPT");
echo -e "\n${PRTY} Changing working location to ${SCRIPTPATH}.";
cd ${SCRIPTPATH};

# . ./admin_utils.sh;
# . ./utils.sh;

#  sourceSemVerToolkit;  ### FIXME ?? DID WE EVER NEED THIS ???


PRTY="PIStT  ==> ";

TARGET_SRVR=${1};
SETUP_USER_UID=${2};
# METEOR_SETTINGS_FILE=${3};
SOURCE_SECRETS_DIR=${3};
ENVIRONMENT=${4};

DH_PARAMS_DIR="${SOURCE_SECRETS_DIR}/dh";
SOURCE_SECRETS_FILE="${SOURCE_SECRETS_DIR}/secrets.json";


PASSWORD_MINIMUM_LENGTH=4;

echo -e "${PRTY} TARGET_SRVR=${TARGET_SRVR}";
echo -e "${PRTY} SETUP_USER_UID=${SETUP_USER_UID}";
# echo -e "${PRTY} METEOR_SETTINGS_FILE=${METEOR_SETTINGS_FILE}";
echo -e "${PRTY} SOURCE_SECRETS_DIR=${SOURCE_SECRETS_DIR}";
echo -e "${PRTY} SOURCE_SECRETS_FILE=${SOURCE_SECRETS_FILE}";
echo -e "${PRTY} ENVIRONMENT=${ENVIRONMENT}";
echo -e "${PRTY} DH_PARAMS_DIR=${DH_PARAMS_DIR}";

# set -e;

# ----------------
# FIXME : We should be pushing the secrets file, and making settings.json from its template
#
# echo -e "${PRTY} Testing settings file availability... [   ls \"${METEOR_SETTINGS_FILE}\"  ]";
# if [[ "X${METEOR_SETTINGS_FILE}X" = "XX" ]]; then errorNoSettingsFileSpecified "null"; fi;
# if [ "${METEOR_SETTINGS_FILE:0:1}" != "/" ]; then
#   METEOR_SETTINGS_FILE="${CURR_DIR}/${METEOR_SETTINGS_FILE}";
# fi;
# if [ ! -f "${METEOR_SETTINGS_FILE}" ]; then errorNoSettingsFileSpecified "${METEOR_SETTINGS_FILE}"; fi;
# if [ ! -s "${METEOR_SETTINGS_FILE}" ]; then warningEmptySettingsFileSpecified "${METEOR_SETTINGS_FILE}"; fi;

# ----------------
echo -e "${PRTY} Testing secrets directory existence ... [   ls \"${SOURCE_SECRETS_DIR}\"  ]";
if [[ "X${SOURCE_SECRETS_DIR}X" = "XX" ]]; then errorNoSecretsDirSpecified "null"; fi;
if [ ! -f "${SOURCE_SECRETS_FILE}" ]; then errorNoSecretsDirSpecified "${SOURCE_SECRETS_FILE}"; fi;
echo -e "### FIXME must get all secrets from /dev/shm etc...";
# source ${SOURCE_SECRETS_FILE};

# ----------------
echo -e "${PRTY} Testing environment vars file availability... [   ls \"${ENVIRONMENT}\"  ]";
if [[ "X${ENVIRONMENT}X" = "XX" ]]; then errorNoEnvVarsFileSpecified "null"; fi;
if [ ! -f "${ENVIRONMENT}" ]; then errorNoEnvVarsFileSpecified "${ENVIRONMENT}"; fi;
source ${ENVIRONMENT};

# ----------------
echo -e "${PRTY} Testing Diffie-Hellman parameters file availability... [   ls \"${DH_PARAMS_DIR}\"  ]";
if [[ "X${DH_PARAMS_DIR}X" = "XX" ]]; then errorDHParamsFileSpecified "null"; fi;
if [ ! -d ${DH_PARAMS_DIR} ]; then errorDHParamsFileSpecified "${DH_PARAMS_DIR}"; fi;
echo -e "${PRTY} Got $(head -n 2 ${DH_PARAMS_DIR}/dhparams_4096.pem)
";

# ----------------
echo -e "${PRTY} Testing server presence using... [   ping -c 1 ${TARGET_SRVR};   ]";
ping -c 1 ${TARGET_SRVR} >/dev/null || errorCannotPingRemoteServer "${TARGET_SRVR}";


# ----------------
# declare CNT_AGENTS=$(ps au -u $(whoami) | grep -v grep | grep -c ssh-agent);
# if [[ ${CNT_AGENTS} -lt 1  ]]; then
#   echo -e "${PRTY} Start up SSH agent... [   exec ssh-agent bash; ssh-add;  ]";
#   eval $(ssh-agent) > /dev/null;
# fi;

startSSHAgent;
echo -e "${PRTY} Adding keys to ssh-agent";
export KEYPAIR="${HOME}/.ssh/id_rsa";
ssh-add -l | grep -c ${KEYPAIR} >/dev/null || ssh-add ${KEYPAIR};

# # echo ${DEPLOY_USER_SSH_PASS_PHRASE} ${DEPLOY_USER_SSH_KEY_FILE};
# expect << EOF
#   spawn ssh-add ${DEPLOY_USER_SSH_KEY_FILE}
#   expect "Enter passphrase"
#   send "${DEPLOY_USER_SSH_PASS_PHRASE}\r"
#   expect eof
# EOF
echo -e "${PRTY} Added keys to ssh-agent";

# echo -e "${PRTY} SETUP_USER_PWD=${SETUP_USER_PWD}";
# echo -e "${PRTY} DEPLOY_USER_PWD=${DEPLOY_USER_PWD}";
echo -e "${PRTY} DEPLOY_USER_SSH_KEY_PUBL=${DEPLOY_USER_SSH_KEY_PUBL}";

# ----------------
echo -e "${PRTY} Validating target host's user's sudo password... ";
if [[ "X${SETUP_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${SETUP_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${SETUP_USER_PWD};


# ----------------
echo -e "${PRTY} Validating target host's deployment user's sudo password... ";
if [[ "X${DEPLOY_USER_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${DEPLOY_USER_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${DEPLOY_USER_PWD};



# ----------------
echo -e "${PRTY} Validating target host's MongoDB user's password... ";
if [[ "X${NOSQLDB_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${NOSQLDB_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${NOSQLDB_PWD};


# ----------------
echo -e "${PRTY} Validating target host's PostgreSql user's password... ";
if [[ "X${RDBMS_PWD}X" = "XX" ]]; then errorNoSuitablePasswordInFile "null"; fi;
[[ 0 -lt $(echo ${RDBMS_PWD} | grep -cE "^.{${PASSWORD_MINIMUM_LENGTH},}$") ]] ||  errorNoSuitablePasswordInFile ${RDBMS_PWD};


echo -e "DEPLOY_USER_SSH_KEY_PUBL=${DEPLOY_USER_SSH_KEY_PUBL}";
# -----------------
DEPLOY_USER_SSH_KEY_FILE_NAME="authorized_key";
echo -e "${PRTY} Validating target host's user's SSH ${DEPLOY_USER_SSH_KEY_FILE_NAME}... ";
if [[ "X${DEPLOY_USER_SSH_KEY_PUBL}X" = "XX" ]]; then errorBadPathToSSHKey "null"; fi;
ssh-keygen -lvf ${DEPLOY_USER_SSH_KEY_PUBL} > /tmp/kyfp.txt || errorBadPathToSSHKey ${DEPLOY_USER_SSH_KEY_PUBL};
echo -e "${PRTY} Target's user's SSH key fingerprint...";
cat /tmp/kyfp.txt;

BUNDLING_DIRECTORY="${WORKDIR}";
BUNDLE_DIRECTORY_NAME="DeploymentPkgInstallerScripts";
BUNDLE_DIRECTORY="${BUNDLING_DIRECTORY}/${BUNDLE_DIRECTORY_NAME}";
BUNDLED_SECRETS="${BUNDLE_DIRECTORY}/secrets";
BUNDLE_NAME="${BUNDLE_DIRECTORY_NAME}.tar.gz";

echo -e "ENVIRONMENT=${ENVIRONMENT}";
echo -e "SOURCE_SECRETS_DIR=${SOURCE_SECRETS_DIR}";

echo -e "BUNDLE_DIRECTORY=${BUNDLE_DIRECTORY}";
echo -e "BUNDLE_NAME=${BUNDLE_NAME}";
echo -e "BUNDLED_SECRETS=${BUNDLED_SECRETS}";

echo -e "${PRTY} Ready to push deployment scripts to the target server,
       '${TARGET_SRVR}' prior to placing a RPC to install our Meteor project....";

echo -e "${PRTY} Inserting scripts, variables, secrets and keys into, '${BUNDLE_NAME}'...";

echo mkdir -p ${BUNDLED_SECRETS};
echo ${HOST_SCRIPTS};

mkdir -p ${BUNDLED_SECRETS};
cp -rp ${HOST_SCRIPTS}/* ${BUNDLE_DIRECTORY};

# source ${ENVIRONMENT}; # FIXME > !!!  NO LONGER USE secrets.sh  !!!

export LETS_ENCYPT="${HOME}/.ssh/deploy_vault/${VIRTUAL_HOST_DOMAIN_NAME}/letsencrypt.tar.gz";
pushd ${BUNDLING_DIRECTORY} >/dev/null;
  pushd ${BUNDLE_DIRECTORY} >/dev/null;

    cp -p ${ENVIRONMENT} .;
    if [[  -f ${LETS_ENCYPT}  ]]; then
      echo -e "${PRTY} Pushing 'letsencrypt' bundle.";
      cp ${LETS_ENCYPT} .;
    else
      echo -e "${PRTY} Found NO 'letsencrypt' bundle for '${VIRTUAL_HOST_DOMAIN_NAME}'.";
    fi;

    chmod 770 ${SOURCE_SECRETS_DIR};
    cp -pr ${SOURCE_SECRETS_DIR}/. ${BUNDLED_SECRETS};
    rm -f ${BUNDLED_SECRETS}/deploy_user/id_rsa;
    rm -f ${BUNDLED_SECRETS}/secrets.*;
    rm -f ${BUNDLED_SECRETS}/doInit*;
    rm -fr ${BUNDLED_SECRETS}/init;

    echo " #  Passwords # " > ${BUNDLED_SECRETS}/secrets.sh;
    echo "export DEPLOY_USER_SSH_PASS_PHRASE='${DEPLOY_USER_SSH_PASS_PHRASE}';" >> ${BUNDLED_SECRETS}/secrets.sh;
    echo "export DEPLOY_USER_PWD='${DEPLOY_USER_PWD}';" >> ${BUNDLED_SECRETS}/secrets.sh;
    echo "export RDBMS_PWD='${RDBMS_PWD}';" >> ${BUNDLED_SECRETS}/secrets.sh;
    echo "export NOSQLDB_ADMIN_PWD='${NOSQLDB_ADMIN_PWD}';" >> ${BUNDLED_SECRETS}/secrets.sh;
    echo "export RDBMS_ADMIN_PWD='${RDBMS_ADMIN_PWD}';" >> ${BUNDLED_SECRETS}/secrets.sh;
    echo "export NOSQLDB_PWD='${NOSQLDB_PWD}';" >> ${BUNDLED_SECRETS}/secrets.sh;

  popd >/dev/null;

  echo -e "${PRTY} Bundling up the scripts as, '${BUNDLE_NAME}'...";

  tar zcf ${BUNDLING_DIRECTORY}/${BUNDLE_NAME}  --exclude='*.example' ${BUNDLE_DIRECTORY_NAME};
  chmod go-xrw ${BUNDLING_DIRECTORY}/${BUNDLE_NAME};

popd >/dev/null;


echo -e "${PRTY} Pushing the bundle to account name '${SETUP_USER_UID}' on
      host '${TARGET_SRVR}' using SSH key...
       '~/.ssh/id_rsa'...";


scp -p ${BUNDLING_DIRECTORY}/${BUNDLE_NAME} ${SETUP_USER_UID}@${TARGET_SRVR}:/home/${SETUP_USER_UID} >/dev/null || errorFailedToPushBundle;
rm -fr ${BUNDLING_DIRECTORY}/${BUNDLE_NAME};
rm -fr ${BUNDLE_DIRECTORY};


echo -e "${PRTY} Decompressing the bundle...";
ssh ${SETUP_USER_UID}@${TARGET_SRVR} tar zxf ${BUNDLE_NAME} --transform "s/target/${BUNDLE_DIRECTORY_NAME}/" >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Setting up SUDO_ASK_PASS on the target...";
echo "scp ./target/askPassMaker.sh ${SETUP_USER_UID}@${TARGET_SRVR}:~ >/dev/null || errorUnexpectedRPCResult;";
scp ./host_scripts/askPassMaker.sh ${SETUP_USER_UID}@${TARGET_SRVR}:~ >/dev/null || errorUnexpectedRPCResult;
# echo "ssh ${SETUP_USER_UID}@${TARGET_SRVR} \"source askPassMaker.sh; makeAskPassService '${SETUP_USER_UID}' '${SETUP_USER_PWD}';\" >/dev/null || errorUnexpectedRPCResult;";
ssh ${SETUP_USER_UID}@${TARGET_SRVR} "source askPassMaker.sh; makeAskPassService '${SETUP_USER_UID}' '${SETUP_USER_PWD}';"
# >/dev/null || errorUnexpectedRPCResult;

echo -e "${PRTY} Prepare Meteor App Target Server...";
echo -e "ssh ${SETUP_USER_UID}@${TARGET_SRVR} \". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/PrepareMeteorAppTargetServer.sh\";";

ssh ${SETUP_USER_UID}@${TARGET_SRVR} ". .bash_login && ./${BUNDLE_DIRECTORY_NAME}/PrepareMeteorAppTargetServer.sh" || errorUnexpectedRPCResult;

# -------------------
if ! ssh-add -l | grep "${DEPLOY_USER_SSH_KEY_PUBL%.pub}" &>/dev/null; then
  echo -e "${PRTY} Adding deploy_user SSH key passphrase to ssh-agent";
  startSSHAgent;
  expect << EOF
    spawn ssh-add ${DEPLOY_USER_SSH_KEY_PUBL%.pub}
    expect "Enter passphrase"
    send "${DEPLOY_USER_SSH_PASS_PHRASE}\r"
    expect eof
EOF
fi;

echo -e "${PRETTY}Pushed installer scripts to host :: '${TARGET_SRVR}'.";
# -----------------------
echo -e "${PRTY} Testing SSH connection using... [   ssh ${DEPLOY_USER}@${TARGET_SRVR} 'whoami';  ]";
if [[ "X${DEPLOY_USER}X" = "XX" ]]; then errorNoUserAccountSpecified "null"; fi;
REMOTE_USER=$(ssh -qt -oBatchMode=yes -l ${DEPLOY_USER} ${TARGET_SRVR} whoami) || errorCannotCallRemoteProcedure "${DEPLOY_USER}@${TARGET_SRVR}";
[[ 0 -lt $(echo "${REMOTE_USER}" | grep -c "${DEPLOY_USER}") ]] ||  errorUnexpectedRPCResult;

if [[ "${NON_STOP}" = "YES" ]]; then exit 0; fi;

echo -e "\n${PRTY} All files have been pushed to target server.
Exiting '${PRTY}' ...
$(date);
Done.
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . ${REMOTE_USER}
";
exit 0;
