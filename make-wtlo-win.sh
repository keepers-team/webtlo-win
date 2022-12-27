#!/bin/sh
set -e

NGINX_VER=1.22.1
PHP_VER=php-8.2.0-nts-Win32-vs16-x64
WEBTLO_VER=2.9.9-alpha4
SCRIPT_VER=0.2

rm -r webtlo-win
mkdir -p webtlo-win/php

# Nginx: https://nginx.org/en/download.html
wget -O nginx.zip "https://nginx.org/download/nginx-$NGINX_VER.zip"
unzip -d webtlo-win nginx.zip
mv "webtlo-win/nginx-$NGINX_VER" "webtlo-win/nginx"

# PHP: https://windows.php.net/download Non-Thread-Safe
wget -O php.zip "https://windows.php.net/downloads/releases/$PHP_VER.zip"
unzip -d webtlo-win/php php.zip

# Web-TLO: https://github.com/keepers-team/webtlo
wget -O webtlo.zip "https://github.com/keepers-team/webtlo/archive/refs/tags/$WEBTLO_VER.zip"
unzip -d webtlo-win webtlo.zip
mv "webtlo-win/webtlo-$WEBTLO_VER" "webtlo-win/nginx/wtlo"

# RunHiddenConsole https://redmine.lighttpd.net/attachments/660/RunHiddenConsole.zip
wget -O RunHiddenConsole.zip https://redmine.lighttpd.net/attachments/download/660/RunHiddenConsole.zip
unzip -d webtlo-win/php RunHiddenConsole.zip

cat <<'EOF' > webtlo-win/nginx/conf/nginx.conf
worker_processes 1;
error_log  logs/error.log;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    access_log  off;
    sendfile        on;
    keepalive_timeout  65;
    gzip  off;

    server {
        listen       39080;
        server_name  _;
        charset utf-8;
        root   wtlo;
        location / {
            index  index.php;
        }
        location ~ \.php$ {
            fastcgi_pass   127.0.0.1:39081;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_read_timeout 600s;
            include        fastcgi_params;
        }
        location /data {
            deny  all;
        }
    }
}
EOF

cat <<'EOF' > webtlo-win/php/php.ini
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
zend.enable_gc = On
zend.exception_ignore_args = On
zend.exception_string_param_max_len = 0
expose_php = On
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
extension_dir = "ext"
enable_dl = Off
file_uploads = On
upload_max_filesize = 2M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
extension=curl
extension=mbstring
extension=sqlite3
extension=pdo_sqlite
[CLI Server]
cli_server.color = On
[bcmath]
bcmath.scale = 0
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.cookie_samesite =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5
EOF

cat <<'EOF' > webtlo-win/Start.bat
cd nginx
start nginx.exe
cd ..\php
start RunHiddenConsole.exe php-cgi.exe -b 127.0.0.1:39081
start "" http://localhost:39080/
EOF

cat <<'EOF' > webtlo-win/Stop.bat
cd nginx
nginx.exe -s stop
taskkill /im php-cgi.exe
EOF

cat <<'EOF' > webtlo-win/cron-control.bat
cd php
php.exe ..\nginx\wtlo\cron\control.php
EOF

cat <<'EOF' > webtlo-win/cron-reports.bat
cd php
php.exe ..\nginx\wtlo\cron\reports.php
EOF

cat <<'EOF' > webtlo-win/cron-update.bat
cd php
php.exe ..\nginx\wtlo\cron\update.php
EOF

cat <<EOF > webtlo-win/ReadMe.html
<html><body>
<h1>Подготвленный Web-TLO для Windows</h1>
<h2>Особенности и ограничения</h2>
- не поддерживается rtorrent (php8 без xmlrpc)<br>
- Используются порты 39080 (nginx) и 39081 (php-fpm)<br>

<h2>Использование web-интерфейса</h2>
- Запустить Start.bat<br>
- интерфейс доступен на <a href="http://localhost:39080/">http://localhost:39080/</a><br>
- Для остановки web-сервера выполнить Stop.bat<br>
<br>
<h2>Использование скриптов автоматизации</h2>
Скрипты можно выполнять без запуска web-сервера.<br>
Подробнее о скриптах: <a href="https://webtlo.keepers.tech/configuration/automation-scripts/">https://webtlo.keepers.tech/configuration/automation-scripts/</a>

<pre>
Software used:
Nginx $NGINX_VER
PHP $PHP_VER
Web-TLO $WEBTLO_VER
WTLO-WIN $SCRIPT_VER
</pre>
</body></html>
EOF

mkdir -p dist
zip -r -9 "dist/webtlo-win-$WEBTLO_VER-$SCRIPT_VER.zip" webtlo-win

echo Done.