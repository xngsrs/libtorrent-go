FROM cross-compiler:linux-armv6

RUN mkdir -p /build
WORKDIR /build

ENV CXXFLAGS="${CXXFLAGS} -std=c++11" \
    \
    BOOST_VERSION=1.69.0 \
    \
    OPENSSL_VERSION=1.1.1a \
    OPENSSL_SHA256=fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41 \
    OPENSSL_NOOPTS="no-afalgeng no-async no-autoalginit no-autoerrinit no-capieng no-cms no-comp no-deprecated no-dgram no-dso no-dtls no-dynamic-engine no-egd no-engine no-err no-filenames no-gost no-hw no-makedepend no-multiblock no-nextprotoneg no-posix-io no-psk no-rdrand no-sctp no-shared no-sock no-srp no-srtp no-static-engine no-stdio no-threads no-ui-console no-zlib no-zlib-dynamic -fno-strict-aliasing -fvisibility=hidden -Os" \
    OPENSSL_OPTS="threads no-shared linux-armv4 -fPIC" \
    \
    SWIG_VERSION=3.0.12 \
    \
    GOLANG_VERSION=1.11.4 \
    GOLANG_SRC_SHA256=4cfd42720a6b1e79a8024895fa6607b69972e8e32446df76d6ce79801bbadb15 \
    \
    GOLANG_BOOTSTRAP_VERSION=1.4.3 \
    GOLANG_BOOTSTRAP_SHA1=486db10dc571a55c8d795365070f66d343458c48 \
    \
    LIBTORRENT_VERSION=5f715acda6da898cda71012472663c9adaa5a163

# Enable 32 bits binaries
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y libc6-dev:i386 libstdc++6:i386 libgcc1:i386 zlib1g:i386

# Install Boost.System
RUN curl -L https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`.tar.bz2 | tar xvj 1>log && \
    cd boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`/ && \
    ./bootstrap.sh --prefix=${CROSS_ROOT} && \
    echo "using gcc : linux : ${CROSS_TRIPLE}-g++ ;" > ${HOME}/user-config.jam && \
    ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} cxxflags=-fPIC cflags=-fPIC toolset=gcc-linux link=static variant=release threading=multi target-os=linux install && \
    rm -rf ${HOME}/user-config.jam && \
    rm -rf `pwd`

# Install OpenSSL
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tar.gz && \
    echo "$OPENSSL_SHA256  openssl.tar.gz" | sha256sum -c - && \
    tar -xzf openssl.tar.gz && \
    rm openssl.tar.gz && \
    cd openssl-${OPENSSL_VERSION}/ && \
    CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure ${OPENSSL_OPTS} ${OPENSSL_NOOPTS} --prefix=${CROSS_ROOT} 1>log && \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log 2>err && \
    make install 1>log 2>err && \
    rm -rf `pwd`

# Install SWIG
RUN curl -L https://github.com/swig/swig/archive/rel-${SWIG_VERSION}.tar.gz | tar xz && \
    cd swig-rel-${SWIG_VERSION}/ && \
    ./autogen.sh && \
    ./configure && \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log 2>err && \
    make install 1>log 2>err && \
    rm -rf `pwd`
  
# Install Golang
RUN set -ex \
  && mkdir -p /usr/local/bootstrap \
  && wget -q "https://storage.googleapis.com/golang/go1.4-bootstrap-20170518.tar.gz" -O golang.tar.gz \
  && tar -C /usr/local/bootstrap -xzf golang.tar.gz \
  && rm golang.tar.gz \
  && cd /usr/local/bootstrap/go/src \
  && ./make.bash 1>golang.log \
  && export GOROOT_BOOTSTRAP=/usr/local/bootstrap/go \
  \
  && wget -q "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz" -O golang.tar.gz \
  && echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
  && tar -C /usr/local -xzf golang.tar.gz \
  && rm golang.tar.gz \
  && cd /usr/local/go/src \
  && ./make.bash 1>golang.log \
  \
  && CC_FOR_TARGET=${CROSS_TRIPLE}-gcc CXX_FOR_TARGET=${CROSS_TRIPLE}-g++ GOOS=linux GOARCH=arm GOARM=6 CGO_ENABLED=1 ./make.bash --no-clean \
  && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
RUN echo "#define BOOST_SP_USE_PTHREADS" >> ${CROSS_ROOT}/include/boost/config/user.hpp
RUN curl -L https://github.com/ElementumOrg/libtorrent/archive/`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
    cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
    CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
    CFLAGS="${CFLAGS} -O2 -fPIC" \
    CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
    ./autotool.sh && \
    \
    sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
    \
    # CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
    CFLAGS="${CFLAGS} -O2 -fPIC" \
    CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
    ./configure \
        --enable-static \
        --disable-shared \
        --disable-deprecated-functions \
        --host=${CROSS_TRIPLE} \
        --prefix=${CROSS_ROOT} \
        --with-boost=${CROSS_ROOT} --with-boost-libdir=${CROSS_ROOT}/lib && \
    \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) && make install && \
    rm -rf `pwd`

WORKDIR /
