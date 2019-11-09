FROM alpine:3.9

RUN set -x \
    && apk update \
    && apk upgrade --update-cache --available \
    && apk add --update --no-cache rsync git mysql-client openssh-client pcre libsodium argon2-dev curl \
    php7 \
    php7-amqp \
    php7-bcmath \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-gmp \
    php7-iconv \
    php7-imagick \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-mcrypt \
    php7-mongodb \
    php7-openssl \
    php7-opcache \
    php7-pcntl \
    php7-pdo \
    php7-pdo_mysql \
    php7-pear \
    php7-pecl-mongodb \
    php7-pgsql \
    php7-phar \
    php7-sockets \
    php7-redis \
    php7-simplexml \
    php7-sodium \
    php7-tokenizer \
    php7-xml \
    php7-xmlwriter \
    php7-zip \
    php7-pecl-apcu \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --filename=composer --install-dir=/usr/local/bin/ \
    && php -r "unlink('composer-setup.php');" \
    && ln -sf /usr/sbin/php-fpm7 ./usr/sbin/php-fpm \
    && ln -sf /proc/self/fd/2 /var/log/dev.log \
    && addgroup -S www-data --gid 101 \
    && adduser -D -S -h /var/cache/www-data -s /sbin/nologin -G www-data --uid 100 www-data \
    && chown -R www-data:www-data /var/log \
    && mkdir /root/.ssh \
    && chmod -R 700 /root/.ssh 

ADD opcache.ini /etc/php7/conf.d/opcache.ini    
ADD ssh_config /root/.ssh/config
ADD php.ini /etc/php7/php.ini
ADD php-fpm.conf /etc/php7/php-fpm.conf
ADD zz-docker.conf /etc/php7/php-fpm.d/zz-docker.conf
ADD www.conf /etc/php7/php-fpm.d/www.conf

#USER www-data
WORKDIR /var/www

ENTRYPOINT ["php-fpm", "-R", "-y", "/etc/php7/php-fpm.conf"]

ARG UID=1000
ARG GID=1000
ARG XDEBUG=1

RUN apk add --update --no-cache php7-xmlwriter

#COPY ./config/xdebug.ini /etc/php7/conf.d/xdebug.ini

RUN apk --no-cache add shadow && \
    usermod -u $UID www-data && \
    groupmod -g $GID www-data

RUN touch /var/run/php-fpm7.pid && \
    chown www-data:www-data /var/run/php-fpm7.pid

USER www-data

RUN mkdir -p ~/.ssh/ && \
   echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config