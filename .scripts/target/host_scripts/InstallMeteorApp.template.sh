#!/bin/bash
cat <<EOIMA
#!/usr/bin/env bash
#
# grep NVM_DIR \${HOME}/.bashrc > /dev/shm/sourceNVM.sh;
# source /dev/shm/sourceNVM.sh;
source ./${BUNDLE_DIRECTORY_NAME}/secrets/secrets.sh;
source ./${BUNDLE_DIRECTORY_NAME}/environment.sh;
echo -e "-------------> \${RDBMS_PWD}";
echo -e "-------------> \${TARGET_SRVR}";


# sh ${BUNDLE_DIRECTORY_NAME}/settings.json.template.sh > settings.json;

export METEOR_SETTINGS=\$( cat settings.json );
rm -fr settings.json;
export ESCAPED_METEOR_SETTINGS=\$(echo \${METEOR_SETTINGS}  | sed "s|'|\\\\\\'|g"  | sed "s|\\\\\\n|\\\\\\\\\\\\\\n|g" );
# echo \${ESCAPED_METEOR_SETTINGS};

declare METEOR_APP_SETTINGS="override.conf";
declare SYSTEMD_DIR="/etc/systemd/system";
declare THE_SERVICE="meteor_node.service";
sh ${BUNDLE_DIRECTORY_NAME}/meteor_node_override.conf.template.sh > \${METEOR_APP_SETTINGS};
cat \${METEOR_APP_SETTINGS};
sudo -A mkdir -p \${SYSTEMD_DIR}/\${THE_SERVICE}.d;
sudo -A mv \${METEOR_APP_SETTINGS} \${SYSTEMD_DIR}/\${THE_SERVICE}.d;

pushd ${BUNDLE_DIRECTORY_NAME} >/dev/null;
  ./${RDBMS_DIALECT}/LoadBackup.sh;
popd >/dev/null;

echo -e "

???????????????????????????????????????????????????????????????????????????????????????????????????????

";

pushd ${APP_DIRECTORY_NAME} >/dev/null;

  rm -fr bundle;
  rm -fr LATEST;
  rm -fr ${PKG_VERSION};
  echo "Unpacking ...";
  tar zxvf ${COMPLETED_BUNDLE} >/dev/null;
  mv bundle ${PKG_VERSION};
  ln -s \${HOME}/${APP_DIRECTORY_NAME}/${PKG_VERSION} LATEST;
  pushd LATEST/programs/server >/dev/null;
    echo "Installing in \$(pwd) ...";
    npm install;
  popd >/dev/null;
  echo "Done ...";

popd >/dev/null;

sudo -A systemctl daemon-reload;
sudo -A systemctl restart meteor_node.service;

EOIMA
