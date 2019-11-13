FROM alpine:3.9

ENV PHPIZE_DEPS autoconf dpkg-dev dpkg file g++ gcc libc-dev make	pkgconf re2c argon2-dev coreutils curl-dev libedit-dev libsodium-dev libxml2-dev openssl-dev sqlite-dev
ENV PHP_DEPS build-base autoconf curl-dev gmp-dev libpng-dev libxml2-dev libmcrypt-dev rabbitmq-c-dev imagemagick-dev icu-dev librdkafka-dev libzip-dev

RUN set -eux \
    && apk update \
    && apk upgrade --update-cache --available \
    && apk add --update --no-cache ca-certificates curl tar xz openssl git mysql-client openssh-client pcre gmp rabbitmq-c imagemagick icu librdkafka libmcrypt

RUN set -eux; \
	addgroup -S www-data --gid 101; \
	adduser -D -S -h /var/cache/www-data -s /sbin/nologin -G www-data --uid 100 www-data

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	[ ! -d /var/www ]; \
	mkdir -p /var/www; \
	chown www-data:www-data /var/www; \
	chmod 777 /var/www

ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi --enable-embed

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F

ENV PHP_VERSION 7.2.18
ENV PHP_URL="https://www.php.net/get/php-7.2.18.tar.xz/from/this/mirror" PHP_ASC_URL="https://www.php.net/get/php-7.2.18.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="9970dbb3ab1298c9e6aac54bebfa841c8ad14b18eead65594a68fa841364cb8d" PHP_MD5=""

RUN set -eux; \
	apk add --no-cache --virtual .fetch-deps gnupg; \
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	if [ -n "$PHP_MD5" ]; then \
		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
	fi; \
	if [ -n "$PHP_ASC_URL" ]; then \
		curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	apk del --no-network .fetch-deps

COPY docker-php-source /usr/local/bin/

RUN set -eux; \
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS; \
	export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-password-argon2 \
		--with-sodium=shared \
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		\
		${PHP_EXTRA_CONFIGURE_ARGS:-} \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; \
	make clean; \
	\
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache $runDeps; \
	\
	apk del --no-network .build-deps; \
	\
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	php --version

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

RUN docker-php-ext-enable sodium
RUN set -eux; \
	cd /usr/local/etc; \
	if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf

RUN set -eux \
	&& apk add --no-cache $PHP_DEPS \
  && docker-php-ext-install -j$(nproc) gd bcmath zip gmp pdo_mysql phar dom opcache pcntl intl sockets \
  && pecl channel-update pecl.php.net \
  && printf "\n" | pecl install amqp imagick mcrypt mongodb redis apcu grpc-1.23.0 rdkafka xdebug \
  && docker-php-ext-enable amqp imagick mcrypt mongodb redis apcu grpc rdkafka xdebug \
  && apk del --purge $PHP_DEPS \
  && rm -vrf /var/cache/apk/* \
  && php -m \
  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php --filename=composer --install-dir=/usr/local/bin/ \
  && php -r "unlink('composer-setup.php');"

RUN set -eux \
    && chown -R www-data:www-data /var/log \
    && mkdir /root/.ssh \
    && chmod -R 700 /root/.ssh

RUN rm -rf /usr/src/php* /tmp/*

ADD ssh_config /root/.ssh/config
ADD php-fpm.conf /usr/local/etc/php-fpm.conf
ADD php.ini-development /usr/local/etc/php/php.ini-development
ADD php.ini-production /usr/local/etc/php/php.ini-production
ADD php.ini-development /usr/local/etc/php/php.ini
ADD www.conf /usr/local/etc/php-fpm.d/www.conf

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm", "-R", "-y", "/usr/local/etc/php-fpm.conf"]
