#!/usr/bin/env bash
#
declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");
declare SCRIPTNAME=$(basename "${SCRIPT}");

function CURTAIL() {  return 0; }

PRTY="\n  ==> Runner ::";
LOG="/tmp/${SCRIPTNAME}.log";
touch ${LOG};

source ${HOME}/.bash_login;

function errorNoSecretsFileSpecified() {
  echo -e "\n\n    *** A valid path to a file of secrets for the remote server needs to be specified, not '${1}'  ***";
  usage;
}


function usage() {
  echo -e "USAGE :

   ./${SCRIPTNAME}

   Expects all parameters to be provided in files in same directory

  ${1}";
  exit 1;
}

NGINX_WORK_DIRECTORY="/etc/nginx";
NGINX_VHOSTS_DEFINITIONS="${NGINX_WORK_DIRECTORY}/sites-available";
NGINX_VHOSTS_PUBLICATIONS="${NGINX_WORK_DIRECTORY}/sites-enabled";
NGINX_ROOT_DIRECTORY="${NGINX_WORK_DIRECTORY}/www-data";
NGINX_VIRTUAL_HOST_FILE_PATH=${NGINX_VHOSTS_DEFINITIONS}/${VIRTUAL_HOST_DOMAIN_NAME};

function prepareNginxVHostDirectories() {

  echo -e "${PRTY} Creating Nginx virtual host directory structure." | tee -a ${LOG};

  sudo -A mkdir -p ${NGINX_VHOSTS_DEFINITIONS};
  sudo -A mkdir -p ${NGINX_VHOSTS_PUBLICATIONS};
  # sudo -A mkdir -p ${NGINX_VHOSTS_CERTIFICATES};
  sudo -A mkdir -p ${NGINX_ROOT_DIRECTORY};
  sh ${SCRIPTPATH}/index.html.template.sh > index.html;
  sudo -A cp index.html ${NGINX_ROOT_DIRECTORY};

  echo -e "${PRTY} Creating Nginx virtual host files '${NGINX_VIRTUAL_HOST_FILE_PATH}' from templates." | tee -a ${LOG};
  sh ${SCRIPTPATH}/virtual.http.host.conf.template.sh > ${VIRTUAL_HOST_DOMAIN_NAME}_NOCERT;
  sh ${SCRIPTPATH}/virtual.https.host.conf.template.sh > ${VIRTUAL_HOST_DOMAIN_NAME}_WITHCERT;
  sudo -A cp ${VIRTUAL_HOST_DOMAIN_NAME}* ${NGINX_VHOSTS_DEFINITIONS};

  # echo -e "${PRTY} Enabling temporary Nginx HTTP virtual host ${VIRTUAL_HOST_DOMAIN_NAME}." | tee -a ${LOG};
  # sudo -A ln -sf ${NGINX_VIRTUAL_HOST_FILE_PATH}_NOCERT ${NGINX_VHOSTS_PUBLICATIONS}/${VIRTUAL_HOST_DOMAIN_NAME};

  echo -e "${PRTY} Enabling Nginx HTTP virtual host ${VIRTUAL_HOST_DOMAIN_NAME}." | tee -a ${LOG};
  sudo -A ln -sf ${NGINX_VIRTUAL_HOST_FILE_PATH}${VIRTUAL_HOST_DOMAIN_NAME}_WITHCERT ${NGINX_VHOSTS_PUBLICATIONS}/${VIRTUAL_HOST_DOMAIN_NAME};
  echo -e "sudo -A ln -sf ${NGINX_VIRTUAL_HOST_FILE_PATH}${VIRTUAL_HOST_DOMAIN_NAME}_WITHCERT ${NGINX_VHOSTS_PUBLICATIONS}/${VIRTUAL_HOST_DOMAIN_NAME};"


  LOG_DIR="/var/log/nginx";
  VHOST_LOG_DIR="${LOG_DIR}/${VIRTUAL_HOST_DOMAIN_NAME}";
  echo -e "${PRTY} Creating logging destinations for virtual host : ${VHOST_LOG_DIR}." | tee -a ${LOG};
  sudo -A mkdir -p ${VHOST_LOG_DIR};
  sudo -A touch ${VHOST_LOG_DIR}/access.log;
  sudo -A touch ${VHOST_LOG_DIR}/error.log;

}

LETSENCRYPT_HOME="/etc/letsencrypt";
LETSENCRYPT_LIVE="${LETSENCRYPT_HOME}/live";
LETSENCRYPT_ARCH="${LETSENCRYPT_HOME}/archive";
LETSENCRYPT_RENEWAL="${LETSENCRYPT_HOME}/renewal";
LETSENCRYPT_ACCTS="${LETSENCRYPT_HOME}/accounts/acme-v01.api.letsencrypt.org/directory";

function obtainLetsEncryptSSLCertificate() {

  echo -e "${PRTY}


  Preparing CertBot (Let's Encrypt) config file '${LETSENCRYPT_HOME}/cli.ini'
                  using '${SCRIPTPATH}/cli.ini.template.sh'
  -------------  ${LETSENCRYPT_HOME}/cli.ini  ---------------

  ";
  sudo -A mkdir -p ${LETSENCRYPT_HOME};
  sudo -A rm -fr ${LETSENCRYPT_HOME}/cli.ini;

  sh ${SCRIPTPATH}/cli.ini.template.sh | sudo -A tee ${LETSENCRYPT_HOME}/cli.ini;
  echo -e "
    Generated  '${LETSENCRYPT_HOME}/cli.ini' from template.
  --------------------------------------------------
  ";


  export REQUEST_CERT="NO";
  export LETSENCRYPT_ACCT_NUM=""; # $(cat ${LETSENCRYPT_RENEWAL}/yourhost.yourpublic.work.conf | grep account | sed -n "/account = /s/account = //p")
  export LETSENCRYPT_CREATION_DATE=""; # $(cat ${LETSENCRYPT_ACCTS}/${LETSENCRYPT_ACCT_NUM}/meta.json | jq -r .creation_dt)

  echo -e "Have renewal directoy?";
  if [[ -d ${LETSENCRYPT_RENEWAL} ]]; then
    echo -e "Yes. Have renewal config file?";
    if [[ -f ${LETSENCRYPT_RENEWAL}/${VIRTUAL_HOST_DOMAIN_NAME}.conf ]]; then
      echo -e "Yes. Check renewal schedule.";
      LETSENCRYPT_ACCT_NUM=$(cat ${LETSENCRYPT_RENEWAL}/${VIRTUAL_HOST_DOMAIN_NAME}.conf | grep account | sed -n "/account = /s/account = //p");
      LETSENCRYPT_CREATION_DATE=$(sudo -A cat ${LETSENCRYPT_ACCTS}/${LETSENCRYPT_ACCT_NUM}/meta.json | jq -r .creation_dt);
      # echo ${LETSENCRYPT_CREATION_DATE};
      RENEWAL_DELAY=80;
      export EXPIRY_CLOSE=$(date "+%F" -d "${LETSENCRYPT_CREATION_DATE}+${RENEWAL_DELAY} days"); # echo ${EXPIRY_CLOSE};
      export TODAY=$(date "+%F"); # echo ${TODAY};
      if [[ ${TODAY} > ${EXPIRY_CLOSE} ]]; then
        echo -e "${TODAY} is more than ${RENEWAL_DELAY} days since ${LETSENCRYPT_CREATION_DATE}, when the certificate was issued.";
        REQUEST_CERT="YES";
      else
        echo -e "Today, ${TODAY} is before certificate expiry, ${EXPIRY_CLOSE}.  Renewal not required";
      fi;
    fi;
  else
    echo -e "Ready to install . . .";
    REQUEST_CERT="YES";
  fi;

  if [[  "${REQUEST_CERT}" = "YES" ]]; then
    echo -e "${PRTY} Installing CertBot certificate";
    sudo -A certbot certonly;
  fi;

}


ENVIRONMENT=${SCRIPTPATH}/environment.sh;
TARGET_SECRETS_PATH=${SCRIPTPATH}/secrets;
TARGET_SECRETS_FILE=${TARGET_SECRETS_PATH}/secrets.sh;
TARGET_SETTINGS_FILE=${SCRIPTPATH}/settings.json;

source ${ENVIRONMENT};
echo "SCRIPTPATH=${SCRIPTPATH}";
echo "ENVIRONMENT=${ENVIRONMENT}";
echo "VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}";
echo "TARGET_SECRETS_FILE=${TARGET_SECRETS_FILE}";

if [[ "X${VIRTUAL_HOST_DOMAIN_NAME}X" = "XX" ]]; then usage "VIRTUAL_HOST_DOMAIN_NAME=${VIRTUAL_HOST_DOMAIN_NAME}"; fi;


echo -e "${PRTY} Testing secrets file availability... [   ls \"${TARGET_SECRETS_FILE}\"  ]";
if [ ! -f "${TARGET_SECRETS_FILE}" ]; then errorNoSecretsFileSpecified "${TARGET_SECRETS_FILE}"; fi;
source ${TARGET_SECRETS_FILE};


echo -e "${PRTY} Install 'incron' daemon.  "  | tee -a ${LOG};
which incrond >/dev/null || sudo -A DEBIAN_FRONTEND=noninteractive apt-get -y install incron;


pushd DeploymentPkgInstallerScripts >/dev/null;

  source environment.sh;

  echo -e " Backend service is : ${RDBMS_DIALECT}

  ";

  echo -e "${PRTY}
  Stopping the Nginx systemd service, in case it's running . . ." | tee -a ${LOG};
  sudo -A systemctl stop nginx.service >> ${LOG} 2>&1;

  prepareNginxVHostDirectories;

  if [[ -f ./secrets/letsencrypt.tar.gz ]]; then
    echo -e "${PRTY}
            # # # Skipping formal SSL certificate installation for now # # #
Extracting $(pwd)/letsencrypt.tar.gz to /etc .....
    ";
    sudo -A tar zxvf ./secrets/letsencrypt.tar.gz -C /etc;
#    sudo -A cp ./secrets/dh/*.pem /etc/ssl/private;
  else
    echo -e " # # # Obtaining SSL certificates for '${VIRTUAL_HOST_DOMAIN_NAME}' # # #  ";
    obtainLetsEncryptSSLCertificate;
  fi;

  sudo -A cp ${SCRIPTPATH}/secrets/dh/dhparams_4096.pem /etc/ssl/private;
  DHP_OK=$?;
  if [ ${DHP_OK} ]; then
    echo -e "
      Installed Diffie-Hellman parameters.
    --------------------------------------------------
    "
  else
    echo -e "
      * * * FAILED TO INSTALL DIFFIE-HELLMAN PARAMETERS * * *
    --------------------------------------------------
    ";
    # exit 1;
  fi;

  echo -e "${PRTY} Substituting Nginx configuration file ." | tee -a ${LOG};
  sudo -A mkdir -p ${NGINX_WORK_DIRECTORY};
  sh ${SCRIPTPATH}/nginx.conf.template.sh > nginx.conf;
  sudo -A cp nginx.conf ${NGINX_WORK_DIRECTORY};

  echo -e "${PRTY} Restarting the Nginx systemd service . . ." | tee -a ${LOG};
  sudo -A systemctl start nginx.service >> ${LOG} 2>&1;

  echo -e "${PRTY} Restarting the MongoDB systemd service . . ." | tee -a ${LOG};
  sudo -A systemctl start mongodb.service >> ${LOG} 2>&1;

  sleep 3;

  export MONGO_ADMIN="admin";
  echo -e "${PRTY} Creating mongo admin user : '${MONGO_ADMIN}'." | tee -a ${LOG};
mongo >> ${LOG} <<EOFA
  use ${MONGO_ADMIN}
  db.createUser({user: "${MONGO_ADMIN}",pwd:"${NOSQLDB_ADMIN_PWD}",roles:[{role:"root",db:"${MONGO_ADMIN}"}]})
EOFA

  echo -e "${PRTY} Creating '${NOSQLDB_DB}' db and owner '${NOSQLDB_UID}'" | tee -a ${LOG};
mongo -u "${MONGO_ADMIN}" -p "${NOSQLDB_ADMIN_PWD}" --authenticationDatabase "${MONGO_ADMIN}" >> ${LOG} <<EOFM
  use ${NOSQLDB_DB}
  db.createUser({user: "${NOSQLDB_UID}",pwd:"${NOSQLDB_PWD}",roles:[{role:"dbOwner",db:"${NOSQLDB_DB}"},"readWrite"]})
EOFM



  source environment.sh;
  # declare VHDN=$(  echo ${VIRTUAL_HOST_DOMAIN_NAME} \
  #                | tr '[:lower:]' '[:upper:]' \
  #                | sed -e "s/\./_/g"
  #               );

  # echo "export SECRETS_DIR=${VHDN}_SECRETS;";
  # eval "export SECRETS_DIR=\${${VHDN}_SECRETS};";
  export SECRETS_DIR="secrets";
  export DEPLOY_USER="${DEPLOY_USER:-hoRroR_1}";

  echo SECRETS_DIR=${SECRETS_DIR};
  echo SECRETS=${SECRETS};
  echo TARGET_SECRETS_PATH=${TARGET_SECRETS_PATH};
  echo DEPLOY_USER=${DEPLOY_USER};


  echo -e "${PRTY} Copying secrets file to '${SECRETS}' directory" | tee -a ${LOG};
  echo -e "sudo -A mkdir -p ${SECRETS} >> ${LOG};";
  echo -e "sudo -A cp -r ${TARGET_SECRETS_PATH}/* ${SECRETS} >> ${LOG};";
  echo -e "sudo -A chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${SECRETS} >> ${LOG};";

  sudo -A mkdir -p ${SECRETS} >> ${LOG};
  sudo -A cp -r ${TARGET_SECRETS_PATH}/* ${SECRETS} >> ${LOG};
  sudo -A chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${SECRETS} >> ${LOG};


  echo -e "${PRTY} Clean up APT dependencies . . ." | tee -a ${LOG};
  sudo apt-get -y update;
  sudo apt-get -y upgrade;
  sudo apt-get -y dist-upgrade;
  sudo apt-get -y clean;
  sudo apt-get -y autoremove;



  declare DEFAULTDB='template1';

  declare SANITY_CHECK="SELECT datname FROM pg_database where datname='${DEFAULTDB}'";
  declare PSQL="psql -w -h localhost -d ${DEFAULTDB}";

  echo -e "
  ##########################################
  function testPostgresState() {
    ${PSQL} -tc \"${SANITY_CHECK}\" 2>/dev/null \
       | grep ${DEFAULTDB} &>/dev/null;
  }
  ###########################################>>>
  ";

  function testPostgresState() {
    ${PSQL} -tc "${SANITY_CHECK}" | grep ${DEFAULTDB} >/dev/null;
  }

  declare SLEEP=2;
  declare REPEAT=60;
  export DELAY=$(( SLEEP * REPEAT ));
  function waitForPostgres() {

    local CNT=${DELAY};
    until testPostgresState || (( CNT-- < 1 ))
    do
      echo -ne "Waiting for PostgreSQL to wake          "\\r;
      echo -ne "Waiting for PostgreSQL to wake ${CNT}"\\r;
      sleep ${SLEEP};
    done;
    # echo -e "Sanity check was :\n  ${SANITY_CHECK}";
    # psql -h localhost -d ${DEFAULTDB} -tc "${SANITY_CHECK}";
    echo -e "

    Stopped waiting with : ${CNT}";

    (( CNT > 0 ))

  }

  waitForPostgres \
     && echo -e "\nPostgres is responding now!" \
     || ( echo -e "\nPostgres failed to respond after ${DELAY} seconds."; exit 1; );

  declare PSQL_DEP="psql -w -U ${DEPLOY_USER} -h localhost -d ${DEFAULTDB}";
  declare PSQL_APP="psql -w -U ${RDBMS_OWNER} -h localhost -d ${RDBMS_DB}";

  declare NO_SUCH_DATABASE=$(${PSQL_DEP} -tc "SELECT datname FROM pg_database WHERE datname='${RDBMS_DB}'");
  if [[ -z ${NO_SUCH_DATABASE} ]]; then
    echo -e "${PRTY} Creating '${RDBMS_DB}' PostgreSql database and owner '${RDBMS_ROLE}'" | tee -a ${LOG};
  (
          ${PSQL_DEP} -tc "CREATE ROLE ${RDBMS_OWNER} PASSWORD '${RDBMS_PWD}' LOGIN;" &&
          ${PSQL_DEP} -tc "GRANT ${RDBMS_ROLE} to ${RDBMS_OWNER};" &&
          ${PSQL_DEP} -tc "CREATE DATABASE ${RDBMS_DB} WITH OWNER ${RDBMS_ROLE};";        )  \
          || ( echo -e "
             *** Failed to create database '${RDBMS_DB}' ***
             ***   Giving up                           *** ";
             exit 1;);
  else
    echo -e "${PRTY} Database '${RDBMS_DB}' already exists." | tee -a ${LOG};
  fi;

  declare PGPASSFILE=${HOME}/.pgpass;
  sed -i "/${RDBMS_OWNER}/d" ${PGPASSFILE}; echo "*:*:*:${RDBMS_OWNER}:${RDBMS_PWD}" >> ${PGPASSFILE};
  cat ${PGPASSFILE};

  echo -e "${PSQL_APP} -tc \"CREATE TABLE cities ( name varchar(80), location point);\";";
  ${PSQL_APP} -tc "CREATE TABLE cities ( name varchar(80), location point);";
  ${PSQL_APP} -tc "DROP TABLE cities;";

  # RDBMS_DB=${PG_DB};
  # RDBMS_OWNER=${PG_UID};
  # echo -e "${PRTY} Creating '${RDBMS_DB}' PostgreSql database and owner '${RDBMS_OWNER}'" | tee -a ${LOG};
  # ${PSQL} -tc "SELECT datname FROM pg_database WHERE datname='${RDBMS_DB}'";
  # echo "--";
  # TEST=$(${PSQL} -tc "SELECT datname FROM pg_database WHERE datname='${RDBMS_DB}'");
  # echo ${TEST} | grep ${RDBMS_DB}  \
  #     ||  (
  #           ${PSQL} -tc "CREATE USER ${RDBMS_OWNER} PASSWORD '${RDBMS_PWD}'" &&
  #           ${PSQL} -tc "CREATE DATABASE ${RDBMS_DB} WITH OWNER ${RDBMS_OWNER}";
  #         )  \
  #         || ( echo -e "
  #            *** Failed to create database '${RDBMS_DB}' ***
  #            ***   Giving up                           *** ";
  #            exit 1;);

  declare SERVER_INITIALIZER=${SCRIPTPATH}/initialize_server.sh;
  echo -e "${PRTY} Ready to restore backup ${RDBMS_BKP}  using script : ${SERVER_INITIALIZER}";
  if [ -f ${SERVER_INITIALIZER} ]; then
    echo -e "${PRTY} Restoring ...";
    chmod ug+x ${SERVER_INITIALIZER};
    ${SERVER_INITIALIZER};
  else
    echo -e "${PRTY} No backup to restore ...";
  fi;

  declare NGINX_VHOST_PUBLIC_DIR="public";

  # declare NGINX_VHOST_CONFIG="${NGINX_VHOSTS_DEFINITIONS}/${VIRTUAL_HOST_DOMAIN_NAME}";
  declare NGINX_VHOST_CONFIG="${NGINX_VHOSTS_PUBLICATIONS}/${VIRTUAL_HOST_DOMAIN_NAME}";

  # cat ${NGINX_VHOST_CONFIG} | sed -n -e "/public/,/}/ p";
  #   cat ${NGINX_VHOST_CONFIG} | sed -n -e "/${NGINX_VHOST_PUBLIC_DIR}/,/}/ p"   | grep root | tr -d '[:space:]';


  declare NGINX_VHOST_ROOT_DIR=$(cat ${NGINX_VHOST_CONFIG} \
       | sed -n -e "/${NGINX_VHOST_PUBLIC_DIR}/,/}/ p" \
       | grep root | tr -d '[:space:]');
  echo -e "${PRTY} NGINX_VHOST_CONFIG = ${NGINX_VHOST_CONFIG}";
  NGINX_VHOST_ROOT_DIR="${NGINX_VHOST_ROOT_DIR#root}";
  NGINX_VHOST_ROOT_DIR="${NGINX_VHOST_ROOT_DIR%\;}";


  echo -e "${PRTY}  - NGINX_VHOST_ROOT_DIR -- ${NGINX_VHOST_ROOT_DIR}";
  declare NGINX_STATIC_FILES_DIR=${NGINX_VHOST_ROOT_DIR}/public;
  declare DEFAULT_METEOR_BUNDLE="${HOME}/${APP_DIRECTORY_NAME}/0.0.0";
  mkdir -p ${DEFAULT_METEOR_BUNDLE};
  chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${HOME}/${APP_DIRECTORY_NAME};
  cp -f node_hello_world.js ${DEFAULT_METEOR_BUNDLE}/main.js;

  declare DEFAULT_METEOR_PUBLIC_DIRECTORY="${DEFAULT_METEOR_BUNDLE}/programs/web.browser/app";
  declare ANDROID_PACKAGE="app.apk";

  mkdir -p ${DEFAULT_METEOR_PUBLIC_DIRECTORY};
  echo "dummy" > ${DEFAULT_METEOR_PUBLIC_DIRECTORY}/${ANDROID_PACKAGE};


  declare LATEST_METEOR_BUNDLE="${HOME}/MeteorApp/LATEST";
  declare METEOR_PUBLIC_DIRECTORY="${LATEST_METEOR_BUNDLE}/programs/web.browser/app";

  mkdir -p ${DEFAULT_METEOR_PUBLIC_DIRECTORY};
  if [[ ! -L  ${LATEST_METEOR_BUNDLE} ]];  then
    ln -s ${DEFAULT_METEOR_BUNDLE} ${LATEST_METEOR_BUNDLE};
  fi;

  # echo -e "

  # ______________________________________________________________________";
  # echo -e "cat ${METEOR_PUBLIC_DIRECTORY}/${ANDROID_PACKAGE}";
  # cat ${METEOR_PUBLIC_DIRECTORY}/${ANDROID_PACKAGE};

  sudo -A mkdir -p ${NGINX_VHOST_ROOT_DIR};


  echo -e "
  ${PRTY} Link Nginx static files directory to Habitat Meteor 'public' directory . . .
      - NGINX_STATIC_FILES_DIR -- ${NGINX_STATIC_FILES_DIR}
      - METEOR_PUBLIC_DIRECTORY -- ${METEOR_PUBLIC_DIRECTORY}
  " | tee -a ${LOG};


  pushd ${NGINX_VHOST_ROOT_DIR} >/dev/null;
  #  echo -e "sudo -A ln -s ${METEOR_PUBLIC_DIRECTORY} ${NGINX_VHOST_PUBLIC_DIR};";
    sudo -A rm -fr ${NGINX_VHOST_PUBLIC_DIR};
    sudo -A ln -s ${METEOR_PUBLIC_DIRECTORY} ${NGINX_VHOST_PUBLIC_DIR};
    ls -l;
  popd >/dev/null;

popd >/dev/null;


echo -e "${PRTY} Installing Node Version Manager..." | tee -a ${LOG};
export NVM_LATEST=$(curl -s https://api.github.com/repos/creationix/nvm/releases/latest |   jq --raw-output '.tag_name';);  echo ${NVM_LATEST};
wget -qO- https://raw.githubusercontent.com/creationix/nvm/${NVM_LATEST}/install.sh | bash;
export NVM_DIR="$HOME/.nvm";
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";

echo -e "${PRTY} Installing NodeJS 'v${METEOR_NODE_VERSION}'" | tee -a ${LOG};
nvm install ${METEOR_NODE_VERSION};


export NODE=$(which node);
echo "NODE = ${NODE}";
export NODE_DIR=${NODE%/bin/node};
echo NODE_DIR=${NODE_DIR};
chmod -R 755 $NODE_DIR/bin/*;
sudo cp -r $NODE_DIR/{bin,lib,share} /usr/local/;



echo -e "${PRTY} Installed NodeJS.  Versions are ::" | tee -a ${LOG};
echo -e "${PRTY}   * nvm : $(nvm --version)" | tee -a ${LOG};
echo -e "${PRTY}   * nnpm : $(npm --version)" | tee -a ${LOG};
echo -e "${PRTY}   * node : $(node --version)" | tee -a ${LOG};
pwd;
echo -e ". ./DeploymentPkgInstallerScripts/nvmStarterMaker.sh
makeNvmStarter ${DEPLOY_USER};
";
. ./DeploymentPkgInstallerScripts/nvmStarterMaker.sh
makeNvmStarter ${DEPLOY_USER};


declare SVC_NAME="meteor_node";
declare SVC_FILE="${SVC_NAME}.service";
declare SVC_PATH="/dev/shm/${SVC_FILE}";
declare TMPLT_NAME="${SVC_FILE}.template.sh";
sh ${SCRIPTPATH}/${TMPLT_NAME} > ${SVC_PATH};
cat ${SVC_PATH};

sudo -A cp ${SVC_PATH} /etc/systemd/system;
sudo -A systemctl enable ${SVC_FILE};

# echo -e "${PRTY} Setting .npm-global";
# mkdir -p ~/.npm-global;
# npm config set prefix "~/.npm-global";

export METEOR_NODE_FLAG="####  Meteor - Node zone";
export FLAG_START="${METEOR_NODE_FLAG} : starts ####";
export FLAG_END="${METEOR_NODE_FLAG} : ends ####";
export BASH_PROFILE="${HOME}/.profile";
export NPM_PREFIX="export PATH=~/.npm-global/bin:\$PATH;";
touch ${BASH_PROFILE};

echo -e "${PRTY} Patching .profile";
export REPLACE_ZONE=$(grep -c "${NPM_PREFIX}" ${BASH_PROFILE});
if [[ "${REPLACE_ZONE}" -lt 1 ]]; then
  echo -e "${FLAG_START}\n${NPM_PREFIX}\n${FLAG_END}" >> ${BASH_PROFILE};
else
  echo -e "Previously configured"
fi;
source ${BASH_PROFILE};

echo -e "${PRTY} Installing knex if not installed.";
export INSTALL_KNEX=$(knex --version 2>/dev/null | grep -c "Knex CLI version");
if [[ "${INSTALL_KNEX}" -lt 1 ]]; then
  echo -e "Not found";
  npm -gy install knex;
fi;
knex --version;

echo -e "

______________________________________________________________________";


# sudo -A ls -l ${META_DIR}/var/logs;
# sudo -A ls -l ${META_DIR}/data/index.html;

echo -e "";
echo -e "";
echo -e "  * * *  Some commands you might find you need  * * *  ";
echo -e "         .  .  .  .  .  .  .  .  .  .  .  .  .  ";
echo -e "";
echo -e "# Strategic";
echo -e "     It's state  :      systemctl list-unit-files --type=service |  grep ${SERVICE_UID}  ";
echo -e "     Enable  it  : sudo systemctl  enable ${UNIT_FILE}  ";
echo -e "     Disable it  : sudo systemctl disable ${UNIT_FILE}  ";
echo -e "";
echo -e "# Tactical";
echo -e "                        systemctl status ${UNIT_FILE}  ";
echo -e "                   sudo systemctl stop ${UNIT_FILE}  ";
echo -e "                   sudo systemctl start ${UNIT_FILE}  ";
echo -e "                   sudo systemctl restart ${UNIT_FILE}  ";

echo -e "# Surveillance";
echo -e "                   sudo journalctl -n 200 -fb -u ${UNIT_FILE}  ";
echo -e "";
echo -e "";

exit 0;


# echo -e "# #-----------------------------------------------------------";
# # ls -l;
# # ls -la ${NVM_DIR};
# pwd;
# hostname;

# CURTAIL && (
#   echo -e "DeploymentPackageRunner Line # 492

#    NGINX_VHOSTS_PUBLICATIONS=${NGINX_VHOSTS_PUBLICATIONS};

#                * * *  CURTAILED * * * ";
# ) && exit || (
#   echo -e "             * * *  NOT curtailed - Start * * * ";
# )
# echo -e "# #-----------------------------------------------------------";
