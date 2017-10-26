#!/usr/bin/env bash

declare PRTY_PG="\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nPostgreSQL -- Installation :: ";

function setUpPostgresAptKey() {

  declare SKIPKEY="/dev/shm/didPGDBKY.lock";
  [ -f ${SKIPKEY} ] && return 0;

  echo -e "${PRTY} Ensuring postgresql client can be installed.  "  | tee -a ${LOG};
  declare PGRES_LST="pgdg.list";
  declare PGRES_APT=${APT_SRC_LST}/${PGRES_LST};
  declare UNIQ=$(lsb_release -sc)"-pgdg";
  declare PGRES_SRC="deb http://apt.postgresql.org/pub/repos/apt/ ${UNIQ} main";

  declare PGRES_APT_KEY_HASH="ACCC4CF8";
  apt-key list | grep ${PGRES_APT_KEY_HASH} &>/dev/null \
      && echo " Have postgresql client apt key." \
      || wget --quiet -O - https://www.postgresql.org/media/keys/${PGRES_APT_KEY_HASH}.asc \
      | sudo -A apt-key add - >/dev/null;

  cat ${PGRES_APT} 2>/dev/null \
      |  grep ${UNIQ} >/dev/null \
      || echo ${PGRES_SRC} \
      |  sudo -A tee ${PGRES_APT};

  touch ${SKIPKEY};
  return 0;

}


function installAndSecurePostgreSQL() {

  declare SKIP="/dev/shm/didPGDB.lock";
  [ -f ${SKIP} ] && return 0;

  echo -e "${PRTY} Installing PostgreSql Client.  "  | tee -a ${LOG};
  APKG="postgresql-client-9.6"; dpkg -s ${APKG} >/dev/null \
    || sudo -A DEBIAN_FRONTEND=noninteractive  apt-get install -y ${APKG} >>  ${LOG};

  echo -e "${PRTY} Installing SQL database service.  "  | tee -a ${LOG};
  APKG="postgresql"; dpkg -s ${APKG} >/dev/null \
    || sudo -A DEBIAN_FRONTEND=noninteractive  apt-get install -y ${APKG};
  APKG="postgresql-contrib"; dpkg -s ${APKG} >/dev/null \
    || sudo -A DEBIAN_FRONTEND=noninteractive  apt-get install -y ${APKG};
  APKG="python-psycopg2"; dpkg -s ${APKG} >/dev/null \
    || sudo -A DEBIAN_FRONTEND=noninteractive  apt-get install -y ${APKG};
  APKG="libpq-dev"; dpkg -s ${APKG} >/dev/null \
    || sudo -A DEBIAN_FRONTEND=noninteractive  apt-get install -y ${APKG};

  declare PGPASSFILE=${DEPLOY_DIR}/.pgpass;
  echo -e "${PRTY} Making '${PGPASSFILE}' for '${DEPLOY_USER}' user  ...";
  sudo -A touch ${PGPASSFILE};
  sudo -A chmod 666 ${PGPASSFILE};
  echo "*:*:*:${DEPLOY_USER}:${DEPLOY_USER_SSH_PASS_PHRASE}" > ${PGPASSFILE};
  sudo -A chmod 0600 ${PGPASSFILE};
  sudo -A chown ${DEPLOY_USER}:${DEPLOY_USER} ${PGPASSFILE};

  PG_USER="postgres";
  sudo -A cp -r postgresql /etc;
  sudo -A chmod -R o-rwx /etc/postgresql;
  sudo -A chown -R ${PG_USER}:${PG_USER} /etc/postgresql;

  sudo -A systemctl restart postgresql.service;
  declare DEFAULTDB='template1';
  echo -e "

      declare NO_SUCH_USER=\$(sudo -Au postgres psql -tc \"SELECT 1 FROM pg_user WHERE usename = '${DEPLOY_USER}'\");
      if [[ -z \${NO_SUCH_USER} ]]; then
        echo -e \"Creating role '${RDBMS_ROLE}'.\" ;
        sudo -Au postgres psql -d template1 \
            -tc \"CREATE ROLE ${RDBMS_ROLE} CREATEDB CREATEROLE;\";
        echo -e \"Creating user '${DEPLOY_USER}'.\" ;
        sudo -Au postgres psql -d template1 \
            -tc \"CREATE USER ${DEPLOY_USER} WITH PASSWORD '${DEPLOY_USER_SSH_PASS_PHRASE}' CREATEDB CREATEROLE;\";
      else
        echo -e \"User '${DEPLOY_USER}' already exists.\" ;
      fi;
      sudo -Au postgres psql -d template1 -tc \"GRANT ALL PRIVILEGES ON DATABASE ${DEFAULTDB} to ${DEPLOY_USER};\";
      sudo -Au postgres psql -d template1 -tc \"GRANT ${RDBMS_ROLE} to ${DEPLOY_USER};\";


  wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
  ";

  declare NO_SUCH_USER=$(sudo -Au postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = '${DEPLOY_USER}'");
  if [[ -z ${NO_SUCH_USER} ]]; then
    echo -e "Creating role '${RDBMS_ROLE}'." ;
    sudo -Au postgres psql -d template1 \
        -tc "CREATE ROLE ${RDBMS_ROLE} CREATEDB CREATEROLE;";
    echo -e "Creating user '${DEPLOY_USER}'." ;
    sudo -Au postgres psql -d template1 \
        -tc "CREATE USER ${DEPLOY_USER} WITH PASSWORD '${DEPLOY_USER_SSH_PASS_PHRASE}' CREATEDB CREATEROLE;";
  else
    echo -e "User '${DEPLOY_USER}' already exists." ;
  fi;

  sudo -Au postgres psql -d template1 -tc "GRANT ALL PRIVILEGES ON DATABASE ${DEFAULTDB} to ${DEPLOY_USER};";
  sudo -Au postgres psql -d template1 -tc "GRANT ${RDBMS_ROLE} to ${DEPLOY_USER};";

  touch ${SKIP};
  return 0;
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  installAndSecurePostgreSQL;
fi;
