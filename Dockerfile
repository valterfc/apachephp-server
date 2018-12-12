FROM php:7.0.32-apache AS webservice

LABEL maintainer="valter@accellog.com"

# ferramentas básicas para o funcionamento
RUN apt-get update \
    && apt-get install -y apt-utils \
    && apt-get install -y vim \
    && apt-get install -y net-tools \
    && apt-get install -y wget

# instalando PostgreSQL PDO
RUN apt-get update \
    && apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

# instalando o componente zip do php
RUN apt-get update \
    && apt-get install -y zlib1g-dev \
    && docker-php-ext-install zip

# o arquivo precisa existir para editar
# Update the PHP.ini file, enable <? ?> tags and quieten logging.
#RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /usr/local/etc/php/php.ini
#RUN sed -i "s/log_errors = Off/log_errors = On/" /usr/local/etc/php/php.ini
#RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR/" /usr/local/etc/php/php.ini

# módulo necessário para redirecionar para HTTPS
RUN a2enmod rewrite \
    && a2enmod socache_shmcb \
    && a2enmod ssl

# instalando composer
# https://hub.docker.com/_/composer/
RUN apt-get update \
    && apt-get install -y git subversion mercurial unzip

RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini"

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.7.3

RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/b107d959a5924af895807021fcef4ffec5a76aa9/web/installer \
    && php -r " \
    \$signature = '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
    && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
    && composer --ansi --version --no-interaction \
    && rm -rf /tmp/* /tmp/.htaccess

# baixando e configurando scripts certbot-auto
RUN  cd /usr/bin \
    && wget https://dl.eff.org/certbot-auto \
    && chmod a+x ./certbot-auto \
    && ./certbot-auto --os-packages-only -n

# não manteve a cópia do arquivo, talvez por causa do "volume"
# Update the default apache site with the config we created.
#ADD ./resource/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# php.ini - não precisa copiar mais, foi configurado no .htaccess
#ADD ./resource/php.ini /usr/local/etc/php/php.ini
#ADD ./resource/php-error.log /var/log/apache2/php-error.log

VOLUME /var/www/html
WORKDIR /var/www/html
EXPOSE 80 80
EXPOSE 443 443
