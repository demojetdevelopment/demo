#!/bin/sh
sed -i 's,''APP_FPM_PORT',"${APP_FPM_PORT}," /etc/nginx/conf.d/upstreams.conf 2> /dev/null 1>&2

nginx -g "daemon off;"