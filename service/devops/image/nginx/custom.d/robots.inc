    location  ~ /robots.txt$ {
        rewrite ^/robots\.txt$ /robots.php last;
    }

    fastcgi_buffers 256 4k;
    fastcgi_buffer_size 64k;
    fastcgi_read_timeout 600;
