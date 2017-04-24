#!/usr/bin/env bash
##################
### LOCALE FIX ###
##################
export LC_ALL="en_US.UTF-8"
#apt-get install language-pack-ru

sudo cat >/etc/default/locale <<EOL
LANG="en_US.UTF-8"
LANGUAGE="en_EN:en"
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE=en_US.UTF-8
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES=en_US.UTF-8
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
EOL

###sudo update-locale LANG=ru_RU.UTF-8

##################################
### NGINX + NGXPAGESPEED + SSL ###
##################################
sudo apt-get update -y
sudo apt-get install -y libssl-dev unzip libpcre3-dev

yes | bash <(curl -f -L -sS https://ngxpagespeed.com/install) \
     --nginx-version 1.12.0 -y -a '--with-http_ssl_module --with-http_gzip_static_module --with-http_gunzip_module --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --with-stream --with-stream_ssl_module --with-mail --with-mail_ssl_module --with-threads --without-http_browser_module --without-http_geo_module --without-http_limit_req_module --without-http_referer_module --without-http_scgi_module --without-http_split_clients_module --without-http_ssi_module --without-http_userid_module --without-http_uwsgi_module'

sudo cp ~/nginx-1.12.0/objs/nginx /usr/sbin/nginx


sudo cat >/lib/systemd/system/nginx.service <<EOL
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

sudo apt-get update

sudo wget -O /usr/local/nginx/conf/nginx.conf https://raw.githubusercontent.com/pashakopot/ubuntu-dev-env/master/nginx.conf

cd /
sudo mkdir webroot
sudo chmod 777 webroot

sudo mkdir /var/ngx_pagespeed_cache
sudo chmod 777 /var/ngx_pagespeed_cache

###############
### MONGODB ###
###############

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl enable mongod.service
sudo service mongod start

###############
### PHP-FPM ###
###############
sudo apt-get install -y php-fpm php-mongodb php-zip php-dom php-mbstring php-curl php-gd php-mcrypt
sudo service php7.0-fpm restart

################
### COMPOSER ###
################

cd /tmp
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir=/usr/sbin --filename=composer
sudo php -r "unlink('composer-setup.php');"

###############
### LARAVEL ###
###############
sudo composer global require "laravel/installer"
cd /webroot
sudo ~/.composer/vendor/bin/laravel new laravel
sudo chown -R www-data:www-data laravel
cd laravel
sudo chmod -R 777 storage
sudo chmod -R 777 bootstrap


sudo systemctl enable nginx.service
sudo service nginx start

###########
### UFW ###
###########

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable



#############
### REDIS ###
#############
sudo apt-get update
sudo apt-get install -y build-essential tcl
cd /tmp
sudo curl -O http://download.redis.io/redis-stable.tar.gz
sudo tar xzvf redis-stable.tar.gz
cd redis-stable
sudo make
sudo make test
sudo make install
sudo mkdir /etc/redis
### sudo cp /tmp/redis-stable/redis.conf /etc/redis
sudo wget -O /etc/redis/redis.conf https://raw.githubusercontent.com/pashakopot/ubuntu-dev-env/master/redis.conf

sudo cat> /etc/systemd/system/redis.service <<EOL
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOL

sudo adduser --system --group --no-create-home redis
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis

sudo systemctl start redis
sudo systemctl enable redis


####################
### NODEJS & NPM ###
####################

sudo apt-get update
sudo apt-get install -y nodejs
sudo apt-get install -y npm

sudo apt-get install htop


exit;



