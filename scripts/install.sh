#!/bin/bash
#/bin/bash /root/app/deploy.sh

# Set HuePages
if grep -q "never" /sys/kernel/mm/transparent_hugepage/enabled; then
  echo "transparent_hugepages is already configured."
else
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
  echo "Disabled transparent_hugepages..."
fi

# Set Host OverCommit Memory.
if grep -q "vm.overcommit_memory" /etc/sysctl.conf; then
  echo "vm.overcommit_memory is already configured."
else
  echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  sysctl vm.overcommit_memory=1
  echo "Enabled vm.overcommit_memory..."
fi

# Make Self Signed Certificate (so nginx works)
if [ ! -f "/root/data/certbot/www/privkey.pem" ]; then
  docker-compose run --rm --entrypoint "openssl req
  -x509
  -nodes
  -newkey rsa:1024
  -days 365
  -keyout /root/app/data/certbot/www/privkey.pem
  -out /root/app/data/certbot/www/fullchain.pem
  -subj '/CN=localhost'" certbot
fi

# Make App Directory
if [ ! -d "/root/app" ]; then
  echo "Installing Application..."
  mkdir /root/app
  chown -R www-data: /root/app
  cd /root/app || exit 1
  git init .
  git remote add origin https://github.com/bayareawebpro/laravel-docker-workflow.git
fi

# Make App Directory
if [ ! -f "/root/app/src/.env" ]; then
  echo "Installing Application Environment File..."
  cp /root/app/src/.env.example /root/app/src/.env
fi

# Make App Directory
echo "Pulling Master Branch..."
cd /root/app || exit 1
git pull origin master

# Install PHP Dependencies
echo "Installing Dependancies..."
docker-compose run --rm --name=php_composer --entrypoint "composer install" php

echo "Starting Application..."
docker-compose up
