satisfy any;

include /etc/nginx/custom.d/whitelist.inc;

deny all;

auth_basic "Restricted TEST";
auth_basic_user_file /etc/nginx/.htpasswd;
