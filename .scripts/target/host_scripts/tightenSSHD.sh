#!/bin/bash
#

export SSHD_CONF="/etc/ssh/sshd_config";

export kyKEXALGO="KexAlgorithms";
export kyCIPHERS="Ciphers";
export kyMACS="MACs";

export KEXALGO="diffie-hellman-group-exchange-sha256,curve25519-sha256@libssh.org";
export CIPHERS="chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes256-gcm@openssh.com";
export MACS="umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com";

export lnKEXALGO="${kyKEXALGO} ${KEXALGO}";
export lnCIPHERS="${kyCIPHERS} ${CIPHERS}";
export lnMACS="${kyMACS} ${MACS}";

# echo -e "${lnKEXALGO}";
# echo -e "${lnCIPHERS}";
# echo -e "${lnMACS}";

# sudo -A tail -n 4 ${SSHD_CONF};

declare RES=$(cat ${SSHD_CONF} | grep -c "${kyKEXALGO}");
if [ ${RES} -gt 0 ]; then
  sudo -A sed -i "/${kyKEXALGO}/c\ ${lnKEXALGO}" ${SSHD_CONF};
else
  echo -e "${lnKEXALGO}" | sudo -A tee -a ${SSHD_CONF};
fi;

declare RES=$(cat ${SSHD_CONF} | grep -c "${kyCIPHERS}");
if [ ${RES} -gt 0 ]; then
  sudo -A sed -i "/${kyCIPHERS}/c\ ${lnCIPHERS}" ${SSHD_CONF};
else
  echo -e "${lnCIPHERS}" | sudo -A tee -a ${SSHD_CONF};
fi;

declare RES=$(cat ${SSHD_CONF} | grep -c "${kyMACS}");
if [ ${RES} -gt 0 ]; then
  sudo -A sed -i "/${kyMACS}/c\ ${lnMACS}" ${SSHD_CONF};
else
  echo -e "${lnMACS}" | sudo -A tee -a ${SSHD_CONF};
fi;

exit 0;
