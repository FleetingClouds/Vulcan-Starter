#!/bin/bash
#
cat <<EOMNO
[Service]
Environment='MONGO_URL=mongodb://${NOSQLDB_UID}:${NOSQLDB_PWD}@localhost:${NOSQLDB_PORT}/${NOSQLDB_DB}'
Environment='ROOT_URL=https://${VIRTUAL_HOST_DOMAIN_NAME}/'
Environment='PORT=3000'
Environment='METEOR_SETTINGS=${ESCAPED_METEOR_SETTINGS}'
EOMNO
