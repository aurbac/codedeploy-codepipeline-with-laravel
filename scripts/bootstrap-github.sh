#!/bin/bash -xe

sudo yum update -y
sudo yum install httpd git ruby wget -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install php-dom php-gd php-mbstring mariadb-server -y

sudo wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto

sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent

sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo rm -rf /var/www/html

sudo git clone https://github.com/aurbac/laravel-our-experiences.git /var/www/html

sudo /usr/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo /usr/bin/php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo /usr/bin/php composer-setup.php
sudo /usr/bin/php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer

sudo cp /var/www/html/.env.example /var/www/html/.env
sudo cp /var/www/html/config/aws.php.example /var/www/html/config/aws.php

sudo sed -i 's/DB_DATABASE=homestead/DB_DATABASE=our_experiences/g' /var/www/html/.env
sudo sed -i 's/DB_USERNAME=homestead/DB_USERNAME=root/g' /var/www/html/.env
sudo sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=/g' /var/www/html/.env

sudo mysql -u root -e "CREATE DATABASE our_experiences CHARACTER SET utf8 COLLATE utf8_general_ci;"

sudo cd /var/www/html
sudo /usr/local/bin/composer install --working-dir=/var/www/html --optimize-autoloader --no-dev
sudo /usr/bin/php /var/www/html/artisan key:generate
sudo /usr/bin/php /var/www/html/artisan config:cache

sudo /usr/bin/php /var/www/html/artisan migrate

sudo chown apache:apache /var/www/html -R
sudo chmod 777 /var/www/html/storage -R

echo "<VirtualHost *:80>" >> /etc/httpd/conf.d/site.conf
echo "    #ServerAdmin webmaster@example.com" >> /etc/httpd/conf.d/site.conf
echo "    DocumentRoot \"/var/www/html/public\"" >> /etc/httpd/conf.d/site.conf
echo "    #ServerName example.com" >> /etc/httpd/conf.d/site.conf
echo "    #ServerAlias www.example.com" >> /etc/httpd/conf.d/site.conf
echo "    ErrorLog \"/var/log/httpd/example.com-error_log\"" >> /etc/httpd/conf.d/site.conf
echo "    CustomLog \"/var/log/httpd/example.com-access_log\" common" >> /etc/httpd/conf.d/site.conf
echo "    <Directory \"/var/www/html/public\">" >> /etc/httpd/conf.d/site.conf
echo "        Options Indexes MultiViews FollowSymLinks" >> /etc/httpd/conf.d/site.conf
echo "        AllowOverride All" >> /etc/httpd/conf.d/site.conf
echo "        Allow from all" >> /etc/httpd/conf.d/site.conf
echo "    </Directory>" >> /etc/httpd/conf.d/site.conf
echo "</VirtualHost>" >> /etc/httpd/conf.d/site.conf

sudo systemctl start httpd
sudo systemctl enable httpd