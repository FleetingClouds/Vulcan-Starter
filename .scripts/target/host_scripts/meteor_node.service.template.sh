#!/bin/bash

cat <<EOMDS
[Service]
ExecStart=/usr/local/bin/node /home/${DEPLOY_USER}/${METEOR_NODE_APP_PATH}/main.js
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=meteor_node
User=$(whoami)
Group=$(whoami)
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOMDS
