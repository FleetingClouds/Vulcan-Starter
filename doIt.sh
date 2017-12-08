#!/usr/bin/env bash
#
declare RAMDSK="/dev/shm";
declare EXCL="${RAMDSK}/rsyncExcludes.txt";
declare BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
declare BASE_NAME=$(basename ${BASE});

cat << EOF > ${EXCL}
.meteor/local
.meteor/versions
node_modules
package-lock.json
EOF

echo rsync -aP --exclude-from=${EXCL} ${BASE} ${RAMDSK}
rsync -aP --exclude-from=${EXCL} ${BASE} ${RAMDSK}

if [[ 0 -eq 0 ]]; then
  rm -fr ./node_modules;
  rm -fr ./.meteor/local;
  rm -fr ./.meteor/versions;
  rm -fr package-lock.json
fi;

meteor npm install;

rm -fr .meteor/local/build/programs/server/.example.sqlite;
# meteor reset;

# # echo -e "Debugging Meteor... in : ${BASE_NAME}";
# # meteor npm run debug;

echo -e "Starting Meteor... in : ${BASE_NAME}";
meteor npm start;
