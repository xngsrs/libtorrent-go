FROM libtorrent-go:musl

RUN mkdir -p /build
WORKDIR /build

RUN wget -q https://musl.cc/arm-linux-musleabihf-cross.tgz -O cross.tgz && \
    tar -xzf cross.tgz -C /usr/ && \
    rm cross.tgz

ENV CROSS_TRIPLE arm-linux-musleabihf
ENV CROSS_ROOT /usr/${CROSS_TRIPLE}-cross
ENV PATH ${PATH}:${CROSS_ROOT}/bin
ENV LD_LIBRARY_PATH ${CROSS_ROOT}/lib:${LD_LIBRARY_PATH}
ENV PKG_CONFIG_PATH ${CROSS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH}

ARG MUSL_VERSION
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
ENV BOOST_CC gcc
ENV BOOST_CXX c++
ENV BOOST_OS linux
ENV BOOST_TARGET_OS linux
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
ENV GOLANG_CC ${CROSS_TRIPLE}-cc
ENV GOLANG_CXX ${CROSS_TRIPLE}-c++
ENV GOLANG_OS linux
ENV GOLANG_ARCH arm
ENV GOLANG_ARM 6
RUN ./build-golang.sh
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
COPY scripts/build-libtorrent.sh /build/
ENV LT_CC ${CROSS_TRIPLE}-gcc
ENV LT_CXX ${CROSS_TRIPLE}-g++
ENV LT_CXXFLAGS -std=c++11 -Wno-psabi
RUN ./build-libtorrent.sh

RUN apk del go
