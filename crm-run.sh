#!/usr/bin/env bash

cd gtr-crm

git pull
composer install -o

bin/console cache:clear
bin/console cache:clear --env=prod
bin/console doctrine:migration:migrate -n

bin/console doctrine:database:create
bin/console doctrine:fixtures:load

cd ../frontend && npm run start:hmr