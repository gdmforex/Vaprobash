#!/usr/bin/env bash

git clone https://github.com/gdmforex/crm.git
cd crm
git checkout dev
composer update -o

bin/console cache:clear
bin/console cache:clear --env=prod
bin/console doctrine:migration:migrate -n

bin/console doctrine:database:create
bin/console doctrine:fixtures:load