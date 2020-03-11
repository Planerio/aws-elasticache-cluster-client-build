FROM debian:10-slim

SHELL ["/bin/bash", "-c"]

# can be 7.1 or later:
ARG PHP_VERSION=7.4
# set to 1 to enable:
ARG ENABLE_IGBINARY=0

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y lsb-release apt-transport-https ca-certificates wget curl locales \
    && \
    if [ "$PHP_VERSION" != "7.3" ]; then \
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    ; fi \
    && apt-get update \
    && apt-get install -y \
        autoconf pkg-config \
        php$PHP_VERSION-cli php-igbinary php-msgpack php-dev libevent-dev zlib1g-dev \
    && if [ $ENABLE_IGBINARY -eq 1 ]; then apt-get install php-igbinary; fi \
    && apt-get clean

RUN mkdir /build

COPY aws-elasticache-cluster-client-libmemcached /build/aws-elasticache-cluster-client-libmemcached
COPY aws-elasticache-cluster-client-memcached-for-php /build/aws-elasticache-cluster-client-memcached-for-php
COPY *.patch /build/

RUN cd /build/aws-elasticache-cluster-client-libmemcached \
    && for F in /build/*.patch; do patch -p1 -i "$F"; done \
    && autoreconf -i \
    && mkdir BUILD \
    && cd BUILD \
    && ../configure --prefix=/usr/local --with-pic --disable-sasl \
    && make -j`nproc` \
    && make install

RUN cd /build/aws-elasticache-cluster-client-memcached-for-php \
    && phpize \
    && ./configure --with-pic --disable-memcached-sasl --enable-memcached-session `if [ $ENABLE_IGBINARY -eq 1 ]; then echo "--enable-memcached-igbinary"; fi` \
    && sed -i "s#-lmemcachedutil#-Wl,-whole-archive /usr/local/lib/libmemcachedutil.a -Wl,-no-whole-archive#" Makefile \
    && sed -i "s#-lmemcached#-Wl,-whole-archive /usr/local/lib/libmemcached.a -Wl,-no-whole-archive#" Makefile \
    && make -j`nproc` \
    && make install

# clean slate for checks:
RUN rm -rf /build

# check that the PHP extension is statically linked to libmemcached:
RUN if ldd `find /usr/lib/php/ -name memcached.so` | grep memcached; then exit 1; fi

# check that the PHP extension can be loaded:
RUN php -dextension=memcached.so -m | grep 'memcached' \
    && php -dextension=memcached.so -r 'new Memcached();' \
    && php -dextension=memcached.so -r 'if (!defined("Memcached::DYNAMIC_CLIENT_MODE")) exit(1);'
