#!/usr/bin/env bash

cd /build
if [ ! -f "golang.tar.gz" ]; then
  wget -q "$GOLANG_SRC_URL" -O golang.tar.gz
fi
echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c -
tar -C /usr/local -xzf golang.tar.gz
rm golang.tar.gz
cd /usr/local/go/src
./make.bash 

CC_FOR_TARGET=${GOLANG_CC} CXX_FOR_TARGET=${GOLANG_CXX} GOOS=${GOLANG_OS} GOARCH=${GOLANG_ARCH} GOARM=${GOLANG_ARM} CGO_ENABLED=1 ./make.bash --no-clean
rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
