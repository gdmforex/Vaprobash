#!/usr/bin/env bash

export LANG=C.UTF-8

PHP_TIMEZONE=$1
HHVM=$2
PHP_VERSION=$3

if [[ $HHVM == "true" ]]; then

    echo ">>> Installing HHVM"

    # Get key and add to sources
    wget --quiet -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
    echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list

    # Update
    sudo apt-get update

    # Install HHVM
    # -qq implies -y --force-yes
    sudo apt-get install -qq hhvm

    # Start on system boot
    sudo update-rc.d hhvm defaults

    # Replace PHP with HHVM via symlinking
    sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60

    sudo service hhvm restart
else
    echo ">>> Installing PHP $PHP_VERSION"
    if [ $PHP_VERSION == "7.0" ]; then
        PHP_PATH="php/7.0"
        PHP_EXEC_VERSION="7.0"
    else
        PHP_PATH="php5"
        PHP_EXEC_VERSION="5"
    fi

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

    if [ $PHP_VERSION == "7.0" ]; then
        sudo add-apt-repository ppa:ondrej/php

        sudo apt-key update
        sudo apt-get update

        sudo apt-get install -qq php7.0-cli php7.0-fpm php7.0-mysql php7.0-pgsql php7.0 php7.0-curl php7.0-gd php7.0-gmp php7.0-json php7.0-opcache php7.0-mcrypt php7.0-intl php7.0-xml php7.0-mbstring
    else

        if [ $PHP_VERSION == "5.5" ]; then
            # Add repo for PHP 5.5
            sudo add-apt-repository -y ppa:ondrej/php5
        else
            # Add repo for PHP 5.6
            sudo add-apt-repository -y ppa:ondrej/php5-5.6
        fi

        sudo apt-key update
        sudo apt-get update

        # Install PHP
        # -qq implies -y --force-yes
        sudo apt-get install -qq php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-memcached php5-imagick php5-intl php5-xdebug

#        # xdebug Config
#        cat > $(find /etc/php5 -name xdebug.ini) << EOF
#zend_extension=$(find /usr/lib/php5 -name xdebug.so)
#xdebug.remote_enable = 1
#xdebug.remote_connect_back = 1
#xdebug.remote_port = 9000
#xdebug.scream=0
#xdebug.cli_color=1
#xdebug.show_local_vars=1
#
#; var_dump display
#xdebug.var_display_max_depth = 5
#xdebug.var_display_max_children = 256
#xdebug.var_display_max_data = 1024
#EOF

    fi

            # Set PHP FPM to listen on TCP instead of Socket
        sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/${PHP_PATH}/fpm/pool.d/www.conf

        # Set PHP FPM allowed clients IP address
        sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/${PHP_PATH}/fpm/pool.d/www.conf

        # Set run-as user for PHP5-FPM processes to user/group "vagrant"
        # to avoid permission errors from apps writing to files
        sudo sed -i "s/user = www-data/user = vagrant/" /etc/${PHP_PATH}/fpm/pool.d/www.conf
        sudo sed -i "s/group = www-data/group = vagrant/" /etc/${PHP_PATH}/fpm/pool.d/www.conf

        sudo sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/${PHP_PATH}/fpm/pool.d/www.conf
        sudo sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/${PHP_PATH}/fpm/pool.d/www.conf
        sudo sed -i "s/listen\.mode.*/listen.mode = 0666/" /etc/${PHP_PATH}/fpm/pool.d/www.conf

        # PHP Error Reporting Config
        sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/${PHP_PATH}/fpm/php.ini
        sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/${PHP_PATH}/fpm/php.ini

        # PHP Date Timezone
        sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/${PHP_PATH}/fpm/php.ini
        sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/${PHP_PATH}/cli/php.ini

        sudo service php${PHP_EXEC_VERSION}-fpm restart

fi
