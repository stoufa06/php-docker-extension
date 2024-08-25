ARG PHPVERSION=8.2.22
ARG EXTENSION_VERSION=1.0
ARG ACTION=create
ARG EXTENSION_NAME=test
ARG SOURCE_FOLDER=src

FROM debian:12 AS essential
ARG PHPVERSION
ARG TARGETARCH
ARG EXTENSION_VERSION


LABEL com.vmware.cp.artifact.flavor="sha256:aadf411dc9ed5199bc7dab48b3e6ce18f8bbee4f170127f5ff1b75cd8035eb36" \
      org.opencontainers.image.base.name="docker.io/soufa06/php-docker-extension:${EXTENSION_VERSION}-${PHPVERSION}" \
      org.opencontainers.image.created="2024-08-21T18:34:00Z" \
      org.opencontainers.image.description="Application packaged by stoufa06." \
      org.opencontainers.image.documentation="https://github.com/stoufa06/php-docker-extension/readme.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="${EXTENSION_VERSION}-${PHPVERSION}-debian-12" \
      org.opencontainers.image.source="https://github.com/stoufa06/php-docker-extension" \
      org.opencontainers.image.title="php-docker-extension" \
      org.opencontainers.image.vendor="stoufa06" \
      org.opencontainers.image.version="1.0"
      
ENV OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-12" \
    OS_NAME="linux" \
    APP_VERSION="1.0" \
    PHP_PATH=/opt/php-src \
    HOME=/home

ENV PATH=$PHP_PATH/php-bin/DEBUG/bin:$PATH \
    EXT_PATH=$HOME/ext-php \
    PHP_INI_PATH=$PHP_PATH/php-bin/DEBUG/etc/php.ini

COPY essential/prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]


RUN install_packages build-essential autoconf automake bison flex re2c gdb \
    libtool make pkgconf valgrind git libxml2-dev libsqlite3-dev ca-certificates \
    libssl-dev pkg-config zlib1g-dev libbz2-dev libcurl4-openssl-dev libpng-dev \
    libjpeg-dev libwebp-dev libfreetype6-dev libgmp-dev libldb-dev libldap2-dev \
    libonig-dev libpq-dev libreadline-dev libsodium-dev libzip-dev libtidy-dev \ 
    libxslt-dev freetds-dev freetds-bin autoconf

RUN apt-get update && apt-get upgrade -y && \
apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives


FROM essential AS php-clone
ARG PHPVERSION
RUN git clone --branch PHP-${PHPVERSION} --depth 1 https://github.com/php/php-src.git $PHP_PATH 
COPY php-clone/postbuildfs /

FROM php-clone AS php-build
RUN <<EOF

cd $PHP_PATH 
./buildconf --force
./configure --enable-debug --prefix=$PHP_PATH/php-bin/DEBUG  --with-config-file-path=$PHP_PATH/php-bin/DEBUG/etc --with-zlib-dir --with-zlib \
    --with-libxml-dir=/usr --enable-soap --disable-rpath --enable-inline-optimization --with-bz2 --enable-sockets --enable-pcntl \
    --enable-exif --enable-bcmath --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-png-dir=/usr --with-openssl \
    --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --enable-calendar --with-gettext --with-xmlrpc --with-xsl --enable-fpm \
    --with-fpm-user=daemon --with-fpm-group=daemon --enable-mbstring --enable-cgi --enable-ctype --enable-session --enable-mysqlnd \
    --enable-intl --with-iconv --with-pdo_sqlite --with-sqlite3 --with-readline --with-gmp --with-curl --with-pdo-pgsql=shared \
    --with-pgsql=shared --with-config-file-scan-dir=$PHP_PATH/php-bin/DEBUG/etc/conf.d --enable-simplexml --with-sodium --enable-gd --with-pear \
    --with-freetype --with-jpeg --with-webp --with-zip --with-pdo-dblib=shared --with-tidy --with-ldap=/usr/ --enable-apcu=shared
make -j4
make install

EOF


FROM php-build AS ext-copy
ARG SOURCE_FOLDER
COPY $SOURCE_FOLDER $EXT_PATH

FROM php-build AS ext-create
ARG EXTENSION_NAME
RUN <<EOF
cd $PHP_PATH 
mkdir -p $EXT_PATH
php ext/ext_skel.php --ext ${EXTENSION_NAME} --dir $EXT_PATH
EOF

FROM ext-${ACTION} AS ext-build
ARG EXTENSION_NAME
RUN <<EOF
cd $EXT_PATH/${EXTENSION_NAME}
phpize
./configure
make
make install
EOF

RUN echo -e "\nextension=${EXTENSION_NAME}.so" >> $PHP_INI_PATH
# RUN cat $PHP_INI_PATH
RUN php -m | grep ${EXTENSION_NAME}

FROM ext-build AS ext-test
RUN echo 'testing php extension'
RUN php -r 'test1();'
RUN php -r 'echo test2();'

FROM scratch AS final
ARG EXTENSION_NAME
# RUN echo $EXT_PATH
COPY --from=ext-test /home/ext-php /


