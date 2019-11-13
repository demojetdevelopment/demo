FROM nginx:1.16.1-alpine

RUN set -exu \
  && ln -sf /proc/1/fd/1 /var/log/nginx/access.log \
	&& ln -sf /proc/1/fd/2 /var/log/nginx/error.log \
  && mkdir -pv /var/www/service/public \
  && mkdir -pv /var/www/public \
  && touch /var/www/service/public/index.php \
  && touch /var/www/public/index.php \
  && mkdir -pv /var/cache/nginx/client_temp \
  && chown -R nginx:nginx /var/cache/ \
  && chown -R nginx:nginx /var/log/nginx \
  && chown -R nginx:nginx /etc/nginx \
  && chown -R nginx:nginx /var/www \
  && touch /run/nginx.pid \
  && chown nginx:nginx /run/nginx.pid

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d
COPY custom.d /etc/nginx/custom.d

EXPOSE 80 443 8081

CMD ["nginx", "-g", "daemon off;"]

ARG SERVER_NAME=localhost

COPY ./config/ /etc/nginx/conf.d/

RUN grep -q 'server_name' /etc/nginx/conf.d/application.conf || sed -i "/listen/a server_name $SERVER_NAME;" /etc/nginx/conf.d/application.conf

# disable http basic auth for dev
RUN sed -i -e "s#include /etc/nginx/custom.d/restrictions.inc;# #g" /etc/nginx/conf.d/application.conf
