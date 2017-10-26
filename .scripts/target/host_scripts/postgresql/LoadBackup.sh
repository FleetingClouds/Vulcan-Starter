#!/usr/bin/env bash
#
source ./secrets/secrets.sh;

if [[ -z ${RDBMS_BKP} ]]; then
  echo -e "${PRTY} No PostgreSQL seed URL was specified. Skipping ..."  | tee -a ${LOG};
else

  declare SEED_FILE="pgres_seed.sql";
  echo -e "${PRTY} Downloading and restoring PostgreSQL seed from URL ...
                     ${RDBMS_BKP}
       ... to have internal standard name '${SEED_FILE}'"  | tee -a ${LOG};

  curl -sz ${SEED_FILE} -L -o ${SEED_FILE} ${RDBMS_BKP};

  echo -e "${PRTY} Have seed file, '$(stat -c "%n %s bytes" ${SEED_FILE})'."  | tee -a ${LOG};

  declare SCHEMA_NAME=$(cat ${SEED_FILE} \
    | grep -m 1 -Poh "(?<=\bSCHEMA\s)(\w+)" );

  declare SCHEMA_OWNER=$(cat ${SEED_FILE} \
    | grep "ALTER .* OWNER TO .*;"  \
    | grep -m 1 -oh "TO .*;"  \
    | cut -d " " -f 2  \
    | cut -d ";" -f 1);

  echo -e "${PRTY} Preparing for owner: '${RDBMS_OWNER}'."  | tee -a ${LOG};
  sed -i "s|Owner: ubuntu|Owner: ${RDBMS_OWNER}|g" ${SEED_FILE};
  sed -i "s|OWNER TO ubuntu|OWNER TO ${RDBMS_OWNER}|g" ${SEED_FILE};
  sed -i "s|FROM ubuntu;|FROM ${RDBMS_OWNER};|g" ${SEED_FILE};
  sed -i "s|TO ubuntu;|TO ${RDBMS_OWNER};|g" ${SEED_FILE};
  sed -i "s|_ubuntu.js|_${RDBMS_OWNER}.js|g" ${SEED_FILE};
  grep ubuntu ${SEED_FILE};
  # grep ${RDBMS_OWNER} ${SEED_FILE};

  # echo -e "---------------------------------------------------------------------";
  # exit;

  echo -e "export PSQL=\"psql -h localhost -d ${RDBMS_DB}\"; SN = ${SCHEMA_NAME} SO = ${SCHEMA_OWNER} ";
  export PSQL="psql -h localhost -d ${RDBMS_DB}";

  if [[ -z ${SCHEMA_NAME} ]]; then
    echo -e "No schema name specified... >${SCHEMA_NAME}<"  | tee -a ${LOG};
    SCHEMA_NAME="public";
  else
    echo -e "${PRTY} Seed file specified schema, '${SCHEMA_NAME}'."  | tee -a ${LOG};
    ${PSQL} -tc "CREATE SCHEMA IF NOT EXISTS ${SCHEMA_NAME}";
  fi;

  export SCHEMA_USER="";
  if [[ -z ${SCHEMA_OWNER} ]]; then
    echo -e "${PRTY} No schema owner specified... >${SCHEMA_OWNER}<"  | tee -a ${LOG};
  else
    declare CNT=$(${PSQL} -tc "SELECT count(usename) FROM pg_user WHERE usename = '${SCHEMA_OWNER}'");
    (( ${CNT} < 1 )) && (
      echo "${PRTY} 'Creating user and giving schema ownership" | tee -a ${LOG}
      ${PSQL} -tc "CREATE USER ${SCHEMA_OWNER}";
      ${PSQL} -tc "GRANT ALL PRIVILEGES ON SCHEMA ${SCHEMA_NAME} TO  ${SCHEMA_OWNER}";
    );
  fi;

  declare COUNT_SCHEMA_TABLES="SELECT count(table_name) FROM information_schema.tables WHERE table_schema = '${SCHEMA_NAME}'";
  declare NUM_SCHEMA_TABLES=$(${PSQL} -tc "${COUNT_SCHEMA_TABLES}" | xargs);
  if [[ 0 < ${NUM_SCHEMA_TABLES} ]]; then
    echo -e "${PRTY} Schema, '${SCHEMA_NAME}', has tables already. Skipping..."  | tee -a ${LOG};
  else
    echo -e "${PRTY} Restoring PostgreSQL from seed file, '${SEED_FILE}'."  | tee -a ${LOG};

      ${PSQL} -qf ${SEED_FILE}
      #  &>/dev/null;

    echo -e "${PRTY} Database sown ..."  | tee -a ${LOG};
  fi;

  echo -e "${PRTY} Creating Meteor app user '${RDBMS_UID}' if not exists"  | tee -a ${LOG};
  SCHEMA_USER=$(${PSQL} -tc "SELECT usename FROM pg_user WHERE usename = '${RDBMS_UID}'" | xargs);
  if [[ -z  ${SCHEMA_USER} ]]; then
    ${PSQL} -tc "CREATE USER ${RDBMS_UID} WITH PASSWORD '${PG_PWD}'";
  fi;

  ${PSQL} -tc "GRANT ALL PRIVILEGES ON DATABASE ${RDBMS_DB} TO  ${RDBMS_UID}";
  ${PSQL} -tc "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO ${RDBMS_UID}";
  ${PSQL} -tc "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO ${RDBMS_UID}";

fi;
