#!/bin/bash

cat <<EOVHSCT
## Virtual host configuration file

server {

  listen   80;
  server_name *.${VIRTUAL_HOST_DOMAIN_NAME};
  return   301 https://${VIRTUAL_HOST_DOMAIN_NAME}\$request_uri;
}

server {

  listen   80;
  server_name ${VIRTUAL_HOST_DOMAIN_NAME};
  return   301 https://${VIRTUAL_HOST_DOMAIN_NAME}\$request_uri;
}

server {

  listen 443 ssl http2;
  listen [::]:443 ssl http2;

  server_name ${VIRTUAL_HOST_DOMAIN_NAME};

  access_log /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/access.log;
  error_log  /var/log/nginx/${VIRTUAL_HOST_DOMAIN_NAME}/error.log warn;

  root /usr/share/nginx/org/www;  # IGNORED
  index index.html index.htm;     # IGNORED

  ssl on;
  ssl_certificate     /etc/letsencrypt/live/${VIRTUAL_HOST_DOMAIN_NAME}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${VIRTUAL_HOST_DOMAIN_NAME}/privkey.pem;

  ssl_prefer_server_ciphers on;
  ssl_ciphers 'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS';

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_cache shared:SSL:10m;
  ssl_dhparam /etc/ssl/private/dhparams_4096.pem;

  # allow Nginx to send OCSP results during the connection process
  ssl_stapling on;
  ssl_stapling_verify on;

  ssl_ecdh_curve secp384r1;
  ssl_session_cache shared:SSL:10m;
  ssl_session_tickets off;

  location ^~ /public/ {
    autoindex on;
    root /etc/nginx/www-data;
  }

  location / {

    proxy_pass http://localhost:3000;              # How Nginx finds Meteor app
#                                  see -- http://wiki.nginx.org/HttpProxyModule#proxy_pass

    proxy_hide_header X-Powered-By;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
    add_header Cache-Control no-cache;
    add_header 'Referrer-Policy' 'no-referrer';

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    add_header X-XSS-Protection "1; mode=block";

    proxy_set_header X-Real-IP \$remote_addr;       # http://wiki.nginx.org/HttpProxyModule
    proxy_set_header Host \$host;                   # pass the host header
    proxy_http_version 1.1;                        # recommended with keepalive connections -
#                                  see -- http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version

    # WebSocket proxying - from http://nginx.org/en/docs/http/websocket.html
    proxy_set_header Upgrade \$http_upgrade;        # allow websockets
    proxy_set_header Connection "upgrade";
#  FIXME:::  proxy_set_header X-Forwarded-For \$realip_remote_addr; # preserve client IP


  }

}
EOVHSCT
