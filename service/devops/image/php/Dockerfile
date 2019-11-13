FROM php:7.2.11-fpm-alpine

ARG UID=1000
ARG GID=1000
ARG XDEBUG=1

# Setup
RUN export LANG="en_US.UTF-8"
RUN export LC_ALL="en_US.UTF-8"
RUN export LANGUAGE="en_US.UTF-8"

RUN apk add --update apk-tools

RUN set -xe \
    && apk add --update imagemagick-dev \
    && apk add --no-cache --virtual .php-deps make autoconf freetype-dev libjpeg-turbo-dev libpng-dev g++ \
    icu-dev libmcrypt-dev rabbitmq-c-dev libintl gmp-dev libsodium-dev argon2-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && apk add --no-cache --virtual .build-deps zlib-dev \
    && apk add git openssh

RUN docker-php-source extract \
    && pecl install -o -f mcrypt-1.0.1 imagick redis amqp mongodb \
    && rm -rf /tmp/pear \
    && docker-php-ext-install intl zip bcmath pdo_mysql gmp sockets \
    && docker-php-ext-enable mcrypt redis imagick amqp mongodb gmp sockets \
    && docker-php-source delete

# Install Xdebug
RUN if [ "$XDEBUG" = "1" ]; then docker-php-source extract \
    && pecl install -o -f xdebug \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable xdebug \
    && docker-php-source delete; fi

COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

# Install Composer
RUN export COMPOSER_ALLOW_SUPERUSER=1

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin/ && \
    php -r "unlink('composer-setup.php');"

# Install hirak/prestissimo to speedup composer installs.
RUN composer global require hirak/prestissimo --prefer-dist --no-interaction \
    && rm -rf /root/.composer/cache/*

# Cleanup
RUN apk del --purge .build-deps
RUN rm -rf /var/tmp/* /tmp/*

COPY ../scripts/*.sh /app-scripts/
RUN chmod +x /app-scripts/*.sh

COPY ./config/www.conf /usr/local/etc/php-fpm.d
COPY ./config/php.ini /usr/local/etc/php/php.ini

RUN apk --no-cache add shadow && \
    usermod -u $UID www-data && \
    groupmod -g $GID www-data

WORKDIR /var/www/service

EXPOSE 9000

USER www-data

RUN mkdir -p ~/.ssh/ && \
   echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

CMD ["php-fpm", "--nodaemonize"]