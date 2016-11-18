#!/usr/bin/env bash

# nginx config for backend and frontend
cat <<EOF > gtr-crm.conf
server {
  server_name gtr-crm;

  root  /var/www/gtr-crm/web;

  location ~ /(app|app_dev|config)\.php(/|$) {
       fastcgi_pass 127.0.0.1:9000;
       fastcgi_split_path_info ^(.+\.php)(/.*)$;
       include fastcgi_params;
       fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
       fastcgi_param DOCUMENT_ROOT \$realpath_root;
       fastcgi_param SYMFONY__DATABASE__HOST 127.0.0.1;
       fastcgi_param SYMFONY__DATABASE__NAME gtr-crm;
       fastcgi_param SYMFONY__DATABASE__PORT 5432;
       fastcgi_param SYMFONY__DATABASE__USER vagrant;
       fastcgi_param SYMFONY__DATABASE__PASS vagrant;
  }

  location / {
       alias  /var/www/gtr-crm/web/dist/;
  }

  error_log /var/log/nginx/gtr-crm-error.log;
  access_log /var/log/nginx/gtr-crm-access.log;
}
EOF

sudo cp gtr-crm.conf /etc/nginx/sites-available/gtr-crm.conf

git clone -b dev https://github.com/gdmforex/gtr-crm.git

cd gtr-crm

npm i webpack -g
npm i webpack-dev-server -g
npm i typings -g

cp node_modules /dev/shm/ -R
composer update -o

cd frontend

npm i webpack --save-dev --no-bin-links
npm i webpack-dev-server  --save-dev --no-bin-links
npm i --no-bin-links --save
npm run typings-install

../../crm-run.sh