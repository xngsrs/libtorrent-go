#!/usr/bin/env bash

set -ex
if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
  wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
fi
# echo "$OPENSSL_SHA256  openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c -
tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
rm openssl-${OPENSSL_VERSION}.tar.gz
cd openssl-${OPENSSL_VERSION}/
CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared ${OPENSSL_OPTS} --prefix=${CROSS_ROOT} 1>/dev/null 2>/dev/null
make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>/dev/null 2>/dev/null
make install 1>/dev/null 2>/dev/null
rm -rf `pwd`
