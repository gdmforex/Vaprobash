#!/usr/bin/env bash

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# If HHVM is installed, assume PHP is *not*
[[ $HHVM_IS_INSTALLED -eq 0 ]] && { PHP_IS_INSTALLED=-1; }

echo ">>> Installing Nginx"

[[ -z $1 ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [[ -z $2 ]]; then
    public_folder="/vagrant"
else
    public_folder="$2"
fi

if [[ -z $3 ]]; then
    hostname=""
else
    # There is a space, because this will be suffixed
    hostname=" $3"
fi

if [[ -z $4 ]]; then
    github_url="https://raw.githubusercontent.com/fideloper/Vaprobash/master"
else
    github_url="$4"
fi

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install Nginx
# -qq implies -y --force-yes
sudo apt-get install -qq nginx

# Turn off sendfile to be more compatible with Windows, which can't use NFS
sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

# Set run-as user for PHP5-FPM processes to user/group "vagrant"
# to avoid permission errors from apps writing to files
sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

# Add vagrant user to www-data group
usermod -a -G www-data vagrant

# Nginx enabling and disabling virtual hosts
curl --silent -L $github_url/helpers/ngxen.sh > ngxen
curl --silent -L $github_url/helpers/ngxdis.sh > ngxdis
curl --silent -L $github_url/helpers/ngxcb.sh > ngxcb
sudo chmod guo+x ngxen ngxdis ngxcb
sudo mv ngxen ngxdis ngxcb /usr/local/bin

# Create Nginx Server Block named "vagrant" and enable it
sudo ngxcb -d $public_folder -s "$1.xip.io$hostname" -e

# Disable "default"
sudo ngxdis default

if [[ $HHVM_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -eq 0 ]]; then
    # PHP-FPM Config for Nginx
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

    sudo service php5-fpm restart
fi

# custom config
sudo rm -R /etc/nginx/sites-available/vagrant

sudo su

echo "server {
        listen 80;
        listen 443;

        # Make site accessible from ...
        server_name ~^(.+)\.lc$;

        set \$project_folder $1;

        root /var/www/\$project_folder/public;
        index index.html index.htm index.php app.php app_dev.php;


        access_log /var/log/nginx/\$project_folder-access.log;
        error_log  /var/log/nginx/\$project_folder-error.log error;

        charset utf-8;

        location / {
            try_files $uri $uri/ /app.php?$query_string /index.php?$query_string;
        }

        location = /favicon.ico { log_not_found off; access_log off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        error_page 404 /index.php;

        # pass the PHP scripts to php5-fpm
        # Note: .php$ is susceptible to file upload attacks
        # Consider using: \"location ~ ^/(index|app|app_dev|config).php(/|$) {\"
        location ~ .php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+.php)(/.+)$;
            # With php5-fpm:
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param LARA_ENV dev; # Environment variable for Laravel
            fastcgi_param HTTPS off;
        }

        # Deny .htaccess file access
        location ~ /\.ht {
            deny all;
        }
    }" >>  /etc/nginx/sites-available/vagrant

    exit


sudo service nginx restart
