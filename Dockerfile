FROM ubuntu:18.04

# ARG PHP_VERSION=7.3
# ARG PHALCON_VERSION="3.4.5-1"
# ARG PHPMYADMIN=4.8.5
ENV PHP_VERSION=7.3
ENV PHALCON_VERSION="3.4.5-1"
ENV PHPMYADMIN=4.8.5

COPY ./scripts/autoclean.sh /root/
COPY ./scripts/docker-entrypoint.sh ./misc/cronfile.final ./misc/cronfile.system ./scripts/build.sql /

RUN echo ${PHP_VERSION} > /PHP_VERSION; \
chmod +x /root/autoclean.sh; \
chmod +x /docker-entrypoint.sh; \
#mkdir /app; \
mkdir /run/php/; \
#mkdir -p /var/www; \
apt-get update;

RUN apt-get install -y software-properties-common apt-transport-https \
cron vim ssmtp monit wget unzip curl less git nginx; \
/usr/bin/unattended-upgrades -v;

RUN apt-get install -y nginx;

#php-base
RUN add-apt-repository -y ppa:ondrej/php; \
export DEBIAN_FRONTEND=noninteractive; \
apt-get install -yq php${PHP_VERSION} php${PHP_VERSION}-cli \
php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-json \
php${PHP_VERSION}-mysql php${PHP_VERSION}-opcache php${PHP_VERSION}-readline \
php${PHP_VERSION}-xml php${PHP_VERSION}-xsl php${PHP_VERSION}-gd php${PHP_VERSION}-intl \
php${PHP_VERSION}-bz2 php${PHP_VERSION}-bcmath php${PHP_VERSION}-imap php${PHP_VERSION}-gd \
# php${PHP_VERSION}-mbstring php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-zip php${PHP_VERSION}-odbc php${PHP_VERSION}-snmp;
# php${PHP_VERSION}-interbase php${PHP_VERSION}-ldap php${PHP_VERSION}-tidy 
# php${PHP_VERSION}-memcached php-tcpdf php-redis php-imagick php-mongodb;

#oh maria!
RUN apt-get install -yq mariadb-server mariadb-client; \
cd /usr/share && ( \
  wget -q https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN}/phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
  unzip -oq phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
  mv phpMyAdmin-${PHPMYADMIN}-all-languages pma; \
  rm -f phpMyAdmin-${PHPMYADMIN}-all-languages.zip; \
);

#wp-cli
# RUN mkdir /opt/wp-cli && \
# cd /opt/wp-cli && ( \
#     wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
#     chmod +x /opt/wp-cli/wp-cli.phar; \
#     ln -s /opt/wp-cli/wp-cli.phar /usr/local/bin/wp; \
# )

#let`s compose!
# RUN mkdir /opt/composer; \
# cd /opt/composer && ( \
#     wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet; \
#     ln -s /opt/composer/composer.phar /usr/local/bin/composer; \
# )

COPY ./conf/ssmtp.conf.template /etc/ssmtp/
COPY ./monit/monitrc /etc/monit/
COPY ./monit/cron ./monit/php-fpm ./monit/nginx /etc/monit/conf-enabled/
COPY ./php/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/
COPY ./php/php-fpm.conf ./php/php.ini ./conf/env.conf /etc/php/${PHP_VERSION}/fpm/
COPY ./nginx/default /etc/nginx/sites-enabled/default
COPY ./phpmyadmin/config.inc.php /usr/share/pma/config.inc.php

ENTRYPOINT ["/docker-entrypoint.sh"]
