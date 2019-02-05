FROM cross-compiler:linux-x64

RUN mkdir -p /build
WORKDIR /build

ENV CXXFLAGS="${CXXFLAGS} -std=c++11" \
    \
    BOOST_VERSION=1.69.0 \
    \
    OPENSSL_VERSION=1.1.1a \
    OPENSSL_SHA256=fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41 \
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

# Install Boost.System
RUN curl -L https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`.tar.bz2 | tar xvj && \
    cd boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`/ && \
    ./bootstrap.sh --prefix=${CROSS_ROOT} && \
    echo "using gcc : linux : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
    ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} cxxflags=-fPIC cflags=-fPIC toolset=gcc-linux link=static variant=release threading=multi target-os=linux install 1>log && \
    rm -rf ${HOME}/user-config.jam && \
    rm -rf `pwd`

# Install OpenSSL
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tar.gz && \
    echo "$OPENSSL_SHA256  openssl.tar.gz" | sha256sum -c - && \
    tar -xzf openssl.tar.gz && \
    rm openssl.tar.gz && \
    cd openssl-${OPENSSL_VERSION}/ && \
    CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared linux-x86_64 --prefix=${CROSS_ROOT} 1>log && \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
    make install 1>log && \
    rm -rf `pwd`

# Install SWIG
RUN curl -L https://github.com/swig/swig/archive/rel-${SWIG_VERSION}.tar.gz | tar xz && \
    cd swig-rel-${SWIG_VERSION}/ && \
    ./autogen.sh && \
    ./configure && \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
    make install 1>log && \
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
  && CC_FOR_TARGET=${CROSS_TRIPLE}-cc CXX_FOR_TARGET=${CROSS_TRIPLE}-c++ GOOS=linux GOARCH=amd64 CGO_ENABLED=1 ./make.bash --no-clean \
  && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
RUN curl -L https://github.com/ElementumOrg/libtorrent/archive/`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
    cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
    ./autotool.sh && \
    \
    sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
    \
    CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
    CFLAGS="${CFLAGS} -Os" \
    CXXFLAGS="${CXXFLAGS} ${CFLAGS} -g -ggdb" \
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

# FROM libtorrent-go:base

# ENV CROSS_TRIPLE ${LINUX_X64_CROSS_TRIPLE}
# ENV CROSS_ROOT ${LINUX_X64_CROSS_ROOT}
# ENV PATH ${PATH}:${CROSS_ROOT}/bin
# ENV LD_LIBRARY_PATH ${CROSS_ROOT}/lib:${LD_LIBRARY_PATH}
# ENV PKG_CONFIG_PATH ${CROSS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH}

# ENV GOOS=linux 
# ENV GOARCH=amd64
# ENV GOARM=

# WORKDIR /build

# # Install CRoaring
# RUN cd CRoaring-`echo ${CROARING_VERSION} | sed 's/\\./_/g'`/ && \
#     mkdir -p build && \
#     cd build && \
#     CFLAGS="${CFLAGS} -Os -std=c++11" \
#     cmake .. -DROARING_BUILD_STATIC=ON && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log

# # Install Boost.System
# RUN cd boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`/ && \
#     ./bootstrap.sh --prefix=${CROSS_ROOT} && \
#     echo "using gcc : linux : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" \
#     ./b2 --with-date_time --with-system --with-chrono --with-random debug-symbols=off warnings=off warnings-as-errors=off --prefix=${CROSS_ROOT} cxxflags=-fPIC cflags=-fPIC toolset=gcc-linux link=static variant=release threading=multi target-os=linux install 1>log && \
#     rm -rf ${HOME}/user-config.jam

# # Install OpenSSL
# RUN cd openssl-${OPENSSL_VERSION}/ && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared linux-x86_64 --prefix=${CROSS_ROOT} 1>log && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log

# # Install SWIG
# RUN cd swig-rel-${SWIG_VERSION}/ && \
#     ./autogen.sh && \
#     ./configure 1>log && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log

# # Install Golang
# RUN set -ex \
#   && cd /usr/local/bootstrap/go/src \
#   && ./make.bash 1>golang.log \
#   && export GOROOT_BOOTSTRAP=/usr/local/bootstrap/go \
#   \
#   && cd /usr/local/go/src \
#   && ./make.bash 1>golang.log \
#   \
#   && CC_FOR_TARGET=${CROSS_TRIPLE}-cc CXX_FOR_TARGET=${CROSS_TRIPLE}-c++ GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} CGO_ENABLED=1 ./make.bash --no-clean \
#   && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
# ENV PATH ${PATH}:/usr/local/go/bin

# # Install libtorrent
# RUN cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
#     ./autotool.sh && \
#     \
#     sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
#     \
#     CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
#     CFLAGS="${CFLAGS} -Os -std=c++11" \
#     CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
#     ./configure \
#         --enable-static \
#         --disable-shared \
#         --disable-deprecated-functions \
#         --disable-logging \
#         --host=${CROSS_TRIPLE} \
#         --prefix=${CROSS_ROOT} \
#         --without-python \
#         --with-boost=${CROSS_ROOT} --with-boost-libdir=${CROSS_ROOT}/lib && \
#     \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) && make install

# RUN rm -rf /build

# WORKDIR /
