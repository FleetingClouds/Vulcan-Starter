#!/bin/bash

cat <<EODNC
worker_processes  4;
# daemon off;

events {
    worker_connections  1024;
}

http {
    include        mime.types;
    default_type   application/octet-stream;

    sendfile       on;
    tcp_nopush     on;
    tcp_nodelay    on;

    server_names_hash_bucket_size 96;
    keepalive_timeout 60;

    gzip  on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
    gzip_disable "MSIE [1-6]\.";

    server_tokens off;

    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS';

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Content-Security-Policy "
      default-src 'self';
      script-src 'self';
      img-src 'self';
      style-src 'self';
      font-src 'self' https://themes.googleusercontent.com;
      child-src 'none';
      object-src 'none'";

    add_header 'Referrer-Policy' 'no-referrer';
    add_header 'X-Powered-By' '';
    add_header 'Server' '';

    include /etc/nginx/sites-enabled/*;

}

EODNC
