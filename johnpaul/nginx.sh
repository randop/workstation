#!/usr/bin/env bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
#  nginx.sh
#
#  Copyright © 2010 — 2025 Randolph Ledesma
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

###############################################################################
# Compiling and setup of nginx with OWASP modsecurity
###############################################################################

export MODSEC_TAG=v3.0.14
git clone -b ${MODSEC_TAG} --depth 1 https://github.com/SpiderLabs/ModSecurity.git
cd ModSecurity
git submodule update --init --recursive
sudo apt install \
    git \
    g++ \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    libcurl4-openssl-dev \
    libgeoip-dev \
    liblmdb-dev \
    libpcre2-dev libtool \
    libxml2-dev \
    libyajl-dev \
    pkgconf \
    zlib1g-dev \
    libpcre3-dev \
    libssl-dev \
    libmaxminddb-dev
./build.sh
./configure --with-lmdb --with-pcre2
make
sudo make install

export OWASP_TAG=v4.15.0
git clone -b ${OWASP_TAG} --depth 1 https://github.com/coreruleset/coreruleset.git /usr/local/owasp-modsecurity-crs

export NGINX_VERSION=1.18.0
cd ~/projects
wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
~/projects/nginx-1.18.0
./configure \
    --with-compat \
    --add-dynamic-module=../ngx_http_geoip2_module \
    --add-dynamic-module=../ModSecurity-nginx \
    --with-pcre \
    --with-http_ssl_module \
    --with-debug \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_v2_module \
    --with-http_dav_module \
    --with-http_slice_module \
    --with-threads \
    --with-http_addition_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_sub_module
make modules
sudo cp -v objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
sudo cp -v objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules/