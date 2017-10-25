#!/usr/bin/env bash
#
declare SCRIPT=$(readlink -f "$0");
declare SCRIPTPATH=$(dirname "$SCRIPT");
declare SCRIPTNAME=$(basename "${SCRIPT}");

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

      # declare CP=$(echo "${VIRTUAL_HOST_DOMAIN_NAME}_CERT_PATH" | tr '[:lower:]' '[:upper:]' | tr '.' '_' ;)
      # declare CERT_PATH=$(echo ${!CP});
      # # sudo -A mkdir -p ${CERT_PATH};
      # # sudo -A chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${CERT_PATH};
      # # ls -l "${CERT_PATH}";

      # echo -e "${PRTY} Moving '${VIRTUAL_HOST_DOMAIN_NAME}' site certificate from '${CERT_PATH}'
      #                                     to ${NGINX_VHOSTS_CERTIFICATES}/${VIRTUAL_HOST_DOMAIN_NAME}." | tee -a ${LOG};
      # sudo -A mkdir -p             ${LETSENCRYPT_LIVE}/${VIRTUAL_HOST_DOMAIN_NAME};
      # sudo -A mkdir -p             ${LETSENCRYPT_ARCH}/${VIRTUAL_HOST_DOMAIN_NAME};

      # sudo -A cp ${CERT_PATH}/*.pem    ${LETSENCRYPT_ARCH}/${VIRTUAL_HOST_DOMAIN_NAME};
      # sudo -A chown -R ${DEPLOY_USER}:${DEPLOY_USER}     ${LETSENCRYPT_ARCH}/${VIRTUAL_HOST_DOMAIN_NAME};
      # sudo -A chmod -R go-rwx,u+rw ${LETSENCRYPT_ARCH}/${VIRTUAL_HOST_DOMAIN_NAME};

      # pushd ${LETSENCRYPT_LIVE}/${VIRTUAL_HOST_DOMAIN_NAME} >/dev/null;
      #   sudo -A rm -fr *.pem;
      #   sudo -A ln -s ../../archive/${VIRTUAL_HOST_DOMAIN_NAME}/fullchain.pem fullchain.pem;
      #   sudo -A ln -s ../../archive/${VIRTUAL_HOST_DOMAIN_NAME}/privkey.pem privkey.pem;
      # popd >/dev/null;
      # # ls -l                        ${LETSENCRYPT_LIVE}/${VIRTUAL_HOST_DOMAIN_NAME};

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

  echo -e "

                      ${RDBMS_DIALECT}

  ";

  echo -e "${PRTY}
  Stopping the Nginx systemd service, in case it's running . . ." | tee -a ${LOG};
  sudo -A systemctl stop nginx.service >> ${LOG} 2>&1;

  prepareNginxVHostDirectories;

  if [[ -f letsencrypt.tar.gz ]]; then
    echo -e "${PRTY}
            # # # Skipping formal SSL certificate installation for now # # #
Extracting $(pwd)/letsencrypt.tar.gz to /etc .....
    ";
    sudo -A tar zxvf letsencrypt.tar.gz -C /etc;
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

# echo "Logging '${SCRIPTNAME}' execution to '${LOG}'." | tee ${LOG};
# echo -e "${PRTY} Stopping the '${SERVICE_UID}' systemd service, in case it's running . . ." | tee -a ${LOG};
# sudo -A systemctl stop ${UNIT_FILE} >> ${LOG} 2>&1;

# echo -e "${PRTY} Disabling the '${SERVICE_UID}' systemd service, in case it's enabled . . ." | tee -a ${LOG};
# sudo -A systemctl disable ${UNIT_FILE} >> ${LOG} 2>&1;

# echo -e "${PRTY} Deleting the '${SERVICE_UID}' systemd unit file, in case there's one already . . ." | tee -a ${LOG};
# sudo -A rm /etc/systemd/system/${UNIT_FILE} >> ${LOG} 2>&1;

# echo -e "${PRTY} Deleting director toml file '${DIRECTOR_TOML_FILE_PATH}', in case there's one already . . ." | tee -a ${LOG};
# sudo -A rm -fr ${DIRECTOR_TOML_FILE_PATH} >> ${LOG};

# echo -e "${PRTY} Ensuring Habitat Supervisor is available (installing if necessary...)" | tee -a ${LOG};
# sudo -A ${DEPLOY_USER} install core/${DEPLOY_USER}-sup >> ${LOG} 2>&1;
# sudo -A hab pkg binlink core/hab-sup hab-sup;
# pushd /bin >/dev/null;
#   sudo -A ln -s /usr/local/bin/hab hab;
# popd;

# echo -e "${PRTY} Ensuring Habitat Director is available (installing if necessary...)" | tee -a ${LOG};
# sudo -A hab install core/hab-director; # > /dev/null 2>&1;
# sudo -A hab pkg binlink core/hab-director hab-director;


  echo -e "${PRTY} Restarting the MongoDB systemd service . . ." | tee -a ${LOG};
  sudo -A systemctl start mongodb.service >> ${LOG} 2>&1;

  # MONGO_ORIGIN="billmeyer";
  # # MONGO_ORIGIN="core";
  # MONGO_PKG="mongodb";
  # MONGO_INSTALLER="${MONGO_ORIGIN}/${MONGO_PKG}";
  # echo -e "${PRTY}  --> sudo -A hab pkg install '${MONGO_INSTALLER}'" | tee -a ${LOG};
  # sudo -A hab pkg install ${MONGO_INSTALLER};

  # echo -e "${PRTY} Starting '${MONGO_INSTALLER}' momentarily to set permissions." | tee -a ${LOG};
  # sudo -A hab start ${MONGO_INSTALLER} &

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


  # echo -e "${PRTY} Ensuring package '${PACKAGE_PATH}' is available" | tee -a ${LOG};

  # echo -e "${PRTY}  --> sudo -A hab pkg install '${PACKAGE_PATH}'" | tee -a ${LOG};
  # sudo -A hab pkg install ${PACKAGE_PATH};

  # PACKAGE_ABSOLUTE_PATH=$(sudo -A hab pkg path ${PACKAGE_PATH});

  # PACKAGE_UUID=${PACKAGE_ABSOLUTE_PATH#$DNLD_DIR/};
  # YOUR_PKG_VERSION=$(echo ${PACKAGE_UUID} | cut -d / -f 1);
  # YOUR_PKG_TIMESTAMP=$(echo ${PACKAGE_UUID} | cut -d / -f 2);

  # echo -e "${PRTY} Package universal unique ID is :: '${SERVICE_PATH}/${YOUR_PKG_VERSION}/${YOUR_PKG_TIMESTAMP}'" >>  ${LOG};
  # if [[ "X${YOUR_PKG_VERSION}X" = "XX" ]]; then
  #   echo "Invalid package version '${YOUR_PKG_VERSION}'."  | tee -a ${LOG};
  #   exit 1;
  # fi;
  # if [[ "${#YOUR_PKG_TIMESTAMP}" != "14" ]]; then
  #   echo "Invalid package timestamp '${YOUR_PKG_TIMESTAMP}'."  | tee -a ${LOG};
  #   exit 1;
  # fi;


  # # ps aux | grep mongo;
  # sudo -A pkill hab-sup;
  # wait;



  ### ${YOUR_ORG}/${YOUR_PKG}/${YOUR_PKG_VERSION}/${YOUR_PKG_TIMESTAMP}/


  # sudo -A mkdir -p ${META_DIR};
  # sudo -A mkdir -p ${WORK_DIR};

  # echo -e "${PRTY} Creating director toml file '${DIRECTOR_TOML_FILE_PATH}' from template" | tee -a ${LOG};
  # ${SCRIPTPATH}/director.toml.template.sh > ${SCRIPTPATH}/${DIRECTOR_TOML_FILE};
  # echo -e "${PRTY} Copying director toml file to '${META_DIR}' directory" | tee -a ${LOG};
  # sudo -A cp ${SCRIPTPATH}/${DIRECTOR_TOML_FILE} ${META_DIR} >> ${LOG};

  # echo -e "${PRTY} Creating systemd unit file to 'systemd' directory" | tee -a ${LOG};
  # ${SCRIPTPATH}/systemd.service.template.sh | sudo -A tee ${SCRIPTPATH}/${UNIT_FILE};
  # echo -e "${PRTY} Copying unit file to 'systemd' directory" | tee -a ${LOG};
  # sudo -A cp ${SCRIPTPATH}/${UNIT_FILE} /etc/systemd/system >> ${LOG};

  # echo -e "${PRTY} Creating systemd unit file to 'systemd' directory" | tee -a ${LOG};
  # ${SCRIPTPATH}/supervisor.service.template.sh | sudo -A tee ${SCRIPTPATH}/${UNIT_FILE};
  # echo -e "${PRTY} Copying unit file to 'systemd' directory" | tee -a ${LOG};
  # sudo -A cp ${SCRIPTPATH}/${UNIT_FILE} /etc/systemd/system >> ${LOG};

  # echo -e "${PRTY} Creating user toml file '${USER_TOML_FILE_PATH}' from template" | tee -a ${LOG};
  # ${SCRIPTPATH}/app.user.toml.template.sh > ${SCRIPTPATH}/${USER_TOML_FILE};
  # echo -e "${PRTY} Copying user toml file to '${WORK_DIR}' directory" | tee -a ${LOG};
  # sudo -A cp ${SCRIPTPATH}/${USER_TOML_FILE} ${WORK_DIR} >> ${LOG};

  # ##########################
  # export SECRETS_DIR="$(cat vhost_env_vars.sh \
  #    | grep .ssh \
  #    | grep ${VIRTUAL_HOST_DOMAIN_NAME} \
  #    | cut -d "=" -f 2 \
  #    | sed 's/^"\(.*\)"$/\1/')";

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


  # echo -e "${PRTY} Copying Diffie-Hellman file to SSL directory" | tee -a ${LOG};
  # echo -e " - From : ${SECRETS}/dh/*" | tee -a ${LOG};
  # echo -e " - To   : ${DIFFIE_HELLMAN_DIR}" | tee -a ${LOG};

  # sudo -A mkdir -p ${DIFFIE_HELLMAN_DIR} >> ${LOG};
  # sudo -A touch ${DIFFIE_HELLMAN_DIR}/DiffieHellman_files_go_here >> ${LOG};
  # sudo -A chmod    ug+w         ${DIFFIE_HELLMAN_DIR}/* >> ${LOG};
  # sudo -A cp ${SECRETS}/dh/*    ${DIFFIE_HELLMAN_DIR} >> ${LOG};
  # sudo -A chown -R root:hab     ${DIFFIE_HELLMAN_DIR} >> ${LOG};
  # sudo -A chmod -R ug+rwx,o-rwx ${DIFFIE_HELLMAN_DIR} >> ${LOG};
  # sudo -A ls -l ${DIFFIE_HELLMAN_DIR}/*;
  # sudo -A chmod    ug-w         ${DIFFIE_HELLMAN_DIR}/* >> ${LOG};

  # echo -e "${PRTY} Copying Meteor settings file to '${WORK_DIR}/var' directory" | tee -a ${LOG};
  # sudo -A mkdir -p ${WORK_DIR}/var >> ${LOG};
  # sudo -A cp ${TARGET_SETTINGS_FILE} ${WORK_DIR}/var >> ${LOG};
  # sudo -A chown -R hab:hab ${WORK_DIR}/var >> ${LOG};

  # echo -e "${PRTY} Enabling the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
  # sudo -A systemctl enable ${UNIT_FILE};

  # echo -e "${PRTY} Ensuring there is a directory available for '${SERVICE_UID}' logs" | tee -a ${LOG};
  # sudo -A mkdir -p ${META_DIR}/var/logs; # > /dev/null;

  # .. #  SET UP STUFF THAT HAB PACKAGE OUGHT TO DO FOR ITSELF
  # .. #  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # .. # sudo -A mkdir -p ${META_DIR}/data; # > /dev/null;
  # .. # sudo -A touch ${META_DIR}/data/index.html;
  # .. # sudo -A find ${META_DIR} -type d -print0 | sudo -A xargs -0 chmod 770; # > /dev/null;
  # .. # sudo -A find ${META_DIR} -type f -print0 | sudo -A xargs -0 chmod 660; # > /dev/null;
  # .. # whoami;
  # .. # sudo -A chown -R hab:hab ${META_DIR};
  # .. # sudo -A ls -l ${META_DIR};
  # .. # sudo -A ls -l ${META_DIR}/data;
  # .. # sudo -A ls -l ${META_DIR}/data/index.html;
  # .. # sudo -A echo -e "nginx is ready" >> ${META_DIR}/data/index.html;

  # .. # declare NGINX_CONF="${SVC_DIR}/nginx/config/nginx.conf";
  # declare NGINX_CONFIG_DIR="/hab/pkgs/${YOUR_ORG}/nginx/1.10.1/20161105150115/config";
  # declare NGINX_CONF="${NGINX_CONFIG_DIR}/nginx.conf";
  # echo -e "${PRTY} Ensuring that Nginx bucket size can be set to 64 in '${NGINX_CONF}'." | tee -a ${LOG};

  # declare EXISTING_SETTING="keepalive_timeout";
  # declare MISSING_SETTING="server_names_hash_bucket_size";
  # declare REPLACEMENT="    ${MISSING_SETTING} 64;\n    ${EXISTING_SETTING} 60;";

  # echo -e "${PRTY} Prepare incrond trigger for workaround ." | tee -a ${LOG};

  # declare INCRON_D="/etc/incron.d";
  # declare INCRON_TRIGGER="${INCRON_D}/fixNginxVar";
  # declare NGINX_DIR="/etc/nginx";
  # declare NGINX_VAR_DIR="${NGINX_DIR}/var";
  # declare DEPLOY_USER_SCRIPTS_DIR="/home/${DEPLOY_USER}/scripts";
  # declare NGINX_OWNERSHIP_FIXER="${DEPLOY_USER_SCRIPTS_DIR}/postStartExec.sh";
  # #
  # sudo -A mkdir -m 755 -p ${INCRON_D};
  # sudo -A chown root:root ${INCRON_D};
  # #
  # sudo -A mkdir -m 775 -p ${NGINX_VAR_DIR};
  # sudo -A chown ${DEPLOY_USER}:${DEPLOY_USER} ${NGINX_VAR_DIR};

  # sudo -A mkdir -m 770 -p ${DEPLOY_USER_SCRIPTS_DIR};
  # sudo -A chown ${DEPLOY_USER}:${DEPLOY_USER} ${DEPLOY_USER_SCRIPTS_DIR};


  # sudo tee ${NGINX_OWNERSHIP_FIXER} <<EOHOOK >/dev/null
  # #!/usr/bin/env bash
  # logger  "¬¬¬¬¬¬¬¬   ${INCRON_TRIGGER} ¬¬¬¬¬¬¬¬¬¬";
  # if [[ "\$(stat -c '%U'  ${NGINX_VAR_DIR}/)" = "${DEPLOY_USER}" ]]; then exit 0; fi;
  # logger  "++++    chown ${DEPLOY_USER}:${DEPLOY_USER} ${NGINX_VAR_DIR} ++++++";
  # sleep 5;
  # chmod 775 ${NGINX_VAR_DIR};
  # chown ${DEPLOY_USER}:${DEPLOY_USER} ${NGINX_VAR_DIR};
  # EOHOOK
  # sudo chown root:${DEPLOY_USER} ${NGINX_OWNERSHIP_FIXER};
  # sudo chmod 770      ${NGINX_OWNERSHIP_FIXER};

  # sudo tee ${INCRON_TRIGGER} <<EOID >/dev/null
  # ${NGINX_VAR_DIR}/ IN_ATTRIB ${NGINX_OWNERSHIP_FIXER}
  # EOID
  # sudo chown root:incron ${INCRON_TRIGGER};
  # sudo chmod 600 ${INCRON_TRIGGER};

  # # sudo -A mkdir -p ${NGINX_CONFIG_DIR};
  # # sudo -A touch ${NGINX_CONF};
  # if ! sudo -A grep "${MISSING_SETTING}" ${NGINX_CONF} >/dev/null; then
  #   echo -e "
  #   FIXME : This hack should not be necessary when Habitat accepts my PR.
  #   ";
  #   sudo -A sed -i "s|.*${EXISTING_SETTING}.*|${REPLACEMENT}|" ${NGINX_CONF};
  # fi;
  # sudo -A ls -l ${NGINX_CONFIG_DIR};


  # echo -e "${PRTY} Start up the '${SERVICE_UID}' systemd service . . ." | tee -a ${LOG};
  # echo -e "                 sudo journalctl -n 200 -fb -u ${UNIT_FILE}  " | tee -a ${LOG};

  # sudo -A systemctl start ${UNIT_FILE};

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

  declare DEFAULT_METEOR_BUNDLE="${HOME}/MeteorApp/0.0.0";
  mkdir -p ${DEFAULT_METEOR_BUNDLE};
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



# sudo -A rm -f  /etc/systemd/system/nginx.service;
# sudo -A rm -f  /etc/systemd/system/todos.service;
# # sudo -A rm -f  /etc/systemd/system/multi-user.target.wants/nginx.service;
# sudo -A rm -f  /${DEPLOY_USER}/cache/artifacts/core-nginx-1.10.1-20160902203245-x86_64-linux.hart;
# sudo -A rm -f  /${DEPLOY_USER}/cache/artifacts/fleetingclouds-todos-*.hart;
# sudo -A rm -fr /${DEPLOY_USER}/pkgs/core/nginx;
# sudo -A rm -fr /${DEPLOY_USER}/pkgs/fleetingclouds;
# sudo -A rm -fr ${SVC_DIR}/nginx;
# sudo -A rm -fr ${SVC_DIR}/todos;
# sudo -A rm -fr /home/${DEPLOY_USER}/nginx;

# sudo -A updatedb && locate nginx;
# ----
