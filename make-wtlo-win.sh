#!/bin/sh
set -e

NGINX_VER=1.24.0
PHP_VER=php-8.2.8-nts-Win32-vs16-x64
WEBTLO_VER=2.4.3
SCRIPT_VER=0.10

rm -rf webtlo-win
mkdir -p webtlo-win/php

# Nginx: https://nginx.org/en/download.html
wget -nv -O nginx.zip "https://nginx.org/download/nginx-$NGINX_VER.zip"
unzip -d webtlo-win nginx.zip
mv "webtlo-win/nginx-$NGINX_VER" "webtlo-win/nginx"

# PHP: https://windows.php.net/download Non-Thread-Safe
wget -nv -O php.zip "https://windows.php.net/downloads/releases/$PHP_VER.zip"
unzip -d webtlo-win/php php.zip

# Web-TLO: https://github.com/keepers-team/webtlo
wget -nv -O webtlo.zip "https://github.com/keepers-team/webtlo/archive/refs/tags/$WEBTLO_VER.zip"
unzip -d webtlo-win webtlo.zip
mv "webtlo-win/webtlo-$WEBTLO_VER" "webtlo-win/nginx/wtlo"

# Apply overlays
cp -vr artifacts/* webtlo-win/
cp -vr overlay/* webtlo-win/
mkdir -p dist
zip -r -9 "dist/webtlo-win-$WEBTLO_VER-$SCRIPT_VER.zip" webtlo-win

echo Done.
