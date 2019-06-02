FROM libtorrent-go:base

RUN mkdir -p /build
WORKDIR /build

ENV CROSS_TRIPLE x86_64-apple-darwin15
ENV CROSS_ROOT /usr/${CROSS_TRIPLE}
ENV PATH ${PATH}:${CROSS_ROOT}/bin
ENV LD_LIBRARY_PATH /usr/lib/llvm-4.0/lib:${CROSS_ROOT}/lib:${LD_LIBRARY_PATH}
ENV PKG_CONFIG_PATH ${CROSS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV MAC_SDK_VERSION 10.11

RUN echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-4.0 main" >> /etc/apt/sources.list && \
    curl http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-get update && \
    apt-get install -y --force-yes clang-4.0 llvm-4.0-dev automake autogen \
                                   libtool libxml2-dev uuid-dev libssl-dev bash \
                                   patch make tar xz-utils bzip2 gzip sed cpio

RUN cd / && \
    curl -L https://github.com/tpoechtrager/osxcross/archive/master.tar.gz | tar xz && \
    cd /osxcross-master/ && \
    curl -Lo tarballs/MacOSX${MAC_SDK_VERSION}.sdk.tar.xz \
      https://s3.amazonaws.com/beats-files/deps/MacOSX${MAC_SDK_VERSION}.sdk.tar.xz && \
    ln -s /usr/bin/clang-4.0 /usr/bin/clang && \
    ln -s /usr/bin/clang++-4.0 /usr/bin/clang++ && \
    echo | SDK_VERSION=${MAC_SDK_VERSION} OSX_VERSION_MIN=10.7 UNATTENDED=1 ./build.sh && \
    mv /osxcross-master/target ${CROSS_ROOT} && \
    mkdir -p ${CROSS_ROOT}/lib && \
    cd / && rm -rf /osxcross-master

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

# Fix Boost using wrong archiver / ignoring <archiver> flags
# https://svn.boost.org/trac/boost/ticket/12573
# https://github.com/boostorg/build/blob/boost-1.63.0/src/tools/clang-darwin.jam#L133
RUN mv /usr/bin/ar /usr/bin/ar.orig && \
    mv /usr/bin/strip /usr/bin/strip.orig && \
    mv /usr/bin/ranlib /usr/bin/ranlib.orig && \
    ln -sf ${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar /usr/bin/ar && \
    ln -sf ${CROSS_ROOT}/bin/${CROSS_TRIPLE}-strip /usr/bin/strip && \
    ln -sf ${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ranlib /usr/bin/ranlib

# Install Boost.System
COPY scripts/build-boost.sh /build/
ENV BOOST_CC clang
ENV BOOST_CXX c++
ENV BOOST_OS darwin
ENV BOOST_TARGET_OS darwin
ENV BOOST_BOOTSTRAP --with-toolset=clang
RUN ./build-boost.sh

# Move back ar, strip and ranlib...
RUN mv /usr/bin/ar.orig /usr/bin/ar && \
    mv /usr/bin/strip.orig /usr/bin/strip && \
    mv /usr/bin/ranlib.orig /usr/bin/ranlib

# Install OpenSSL
COPY scripts/build-openssl.sh /build/
ENV OPENSSL_OPTS darwin64-x86_64-cc
RUN ./build-openssl.sh

# Install SWIG
COPY scripts/build-swig.sh /build/
RUN ./build-swig.sh

# Install Golang
COPY scripts/build-golang.sh /build/
ENV GOROOT_BOOTSTRAP /usr/go
ENV GOLANG_CC ${CROSS_TRIPLE}-cc
ENV GOLANG_CXX ${CROSS_TRIPLE}-c++
ENV GOLANG_OS darwin
ENV GOLANG_ARCH amd64
RUN ./build-golang.sh
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
COPY scripts/build-libtorrent.sh /build/
ENV LT_CC ${CROSS_TRIPLE}-cc
ENV LT_CXX ${CROSS_TRIPLE}-c++
ENV LT_OSXCROSS TRUE
ENV LT_CXXFLAGS -Wno-c++11-extensions -Wno-c++11-long-long
RUN ./build-libtorrent.sh

RUN apt -y remove golang-go