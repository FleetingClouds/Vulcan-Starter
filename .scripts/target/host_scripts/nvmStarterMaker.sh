#!/usr/bin/env bash
#
function makeNvmStarter() {

  export PTRN="# start up script for 'nvm'";
  export PTRNB="${PTRN} «begins»";
  export PTRNE="${PTRN} «ends»";
  #
  BL_PATH="/home/${1}/.bash_login";
  touch ${BL_PATH};
  sed -i "/${PTRNB}/,/${PTRNE}/d" ${BL_PATH};
  #
  echo -e "${PTRNB}
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # This loads nvm
[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion
${PTRNE}
" >> ${BL_PATH}
  #
  sed -i "s/ *$//" ${BL_PATH}; # trim whitespace to EOL
  sed -i "/^$/N;/^\n$/D" ${BL_PATH}; # blank lines to 1 line

}

# makeNvmStarter ${USER}
