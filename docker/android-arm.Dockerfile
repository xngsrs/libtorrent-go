FROM libtorrent-go:base

RUN mkdir -p /build
WORKDIR /build

ENV CROSS_TRIPLE arm-linux-androideabi
ENV CROSS_ROOT /usr/${CROSS_TRIPLE}
ENV PATH ${PATH}:${CROSS_ROOT}/bin
ENV LD_LIBRARY_PATH ${CROSS_ROOT}/lib:${LD_LIBRARY_PATH}
ENV PKG_CONFIG_PATH ${CROSS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH}

RUN apt-get update && apt-get install -y python

ENV NDK android-ndk-r14b

RUN set -ex && \
    wget -nv https://dl.google.com/android/repository/${NDK}-linux-x86_64.zip && \
    unzip ${NDK}-linux-x86_64.zip 1>log 2>err && \
    cd ${NDK} && \
    ./build/tools/make_standalone_toolchain.py --arch=arm --api=19 --install-dir=${CROSS_ROOT} && \
    cd /build && mv ${NDK} /usr/

RUN cd ${CROSS_ROOT}/bin && \
    ln -s ${CROSS_TRIPLE}-gcc ${CROSS_TRIPLE}-cc

ARG BOOST_VERSION
ARG BOOST_VERSION_FILE
ARG BOOST_SHA256
ARG OPENSSL_VERSION
ARG OPENSSL_SHA256
ARG SWIG_VERSION
ARG SWIG_SHA256
ARG GOLANG_VERSION
ARG GOLANG_SRC_URL
ARG GOLANG_SRC_SHA256
ARG GOLANG_BOOTSTRAP_VERSION
ARG GOLANG_BOOTSTRAP_URL
ARG GOLANG_BOOTSTRAP_SHA256
ARG LIBTORRENT_VERSION

# Install Boost.System
COPY scripts/build-boost.sh /build/
ENV BOOST_CC clang
ENV BOOST_CXX clang++
ENV BOOST_OS android
ENV BOOST_TARGET_OS linux
ENV BOOST_OPTS cxxflags=-fPIC cflags=-fPIC
RUN ./build-boost.sh

# Install OpenSSL
COPY scripts/build-openssl.sh /build/
ENV OPENSSL_OPTS linux-armv4
RUN ./build-openssl.sh

# Install SWIG
COPY scripts/build-swig.sh /build/
RUN ./build-swig.sh

# Install Golang
COPY scripts/build-golang.sh /build/
ENV GOROOT_BOOTSTRAP /usr/go
ENV GOLANG_CC ${CROSS_TRIPLE}-clang
ENV GOLANG_CXX ${CROSS_TRIPLE}-clang++
ENV GOLANG_OS android
ENV GOLANG_ARCH arm
ENV GOLANG_ARM 7
RUN ./build-golang.sh
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
COPY scripts/build-libtorrent.sh /build/
ENV LT_CC ${CROSS_TRIPLE}-clang
ENV LT_CXX ${CROSS_TRIPLE}-clang++
ENV LT_PTHREADS TRUE
ENV LT_FLAGS -fPIC -DINT64_MAX=0x7fffffffffffffffLL -DINT16_MAX=32767 -DINT16_MIN=-32768 -DTORRENT_PRODUCTION_ASSERTS
ENV LT_CXXFLAGS -Wno-macro-redefined -Wno-c++11-extensions
RUN ./build-libtorrent.sh

RUN apt -y remove golang-go