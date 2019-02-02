FROM cross-compiler:windows-x86

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
    echo "using gcc : mingw32 : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
    ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} toolset=gcc-mingw32 address-model=32 architecture=x86 link=static variant=release threading=multi target-os=windows threadapi=win32 install 1>log && \
    rm -rf ${HOME}/user-config.jam && \
    rm -rf `pwd`

# Install OpenSSL
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tar.gz && \
    echo "$OPENSSL_SHA256  openssl.tar.gz" | sha256sum -c - && \
    tar -xzf openssl.tar.gz && \
    rm openssl.tar.gz && \
    cd openssl-${OPENSSL_VERSION}/ && \
    CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared mingw --prefix=${CROSS_ROOT} 1>log && \
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
  && CC_FOR_TARGET=${CROSS_TRIPLE}-cc CXX_FOR_TARGET=${CROSS_TRIPLE}-c++ GOOS=windows GOARCH=386 CGO_ENABLED=1 ./make.bash --no-clean \
  && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
RUN curl -L https://github.com/ElementumOrg/libtorrent/archive/`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
    cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
    ./autotool.sh && \
    \
    sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
    \
    CC=${CROSS_TRIPLE}-cc CXX=${CROSS_TRIPLE}-c++ \
    CFLAGS="${CFLAGS} -Os -lmswsock -DUNICODE -D_UNICODE -DWIN32 -DWIN32_LEAN_AND_MEAN -DIPV6_TCLASS=39 -D_WIN32_WINNT=0x0501" \
    CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
    LIBS="-lmswsock" \
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

# Install CRoaring
# ENV CROARING_VERSION 6154187fa18728039d757e0f959b120a526e2877
# RUN curl -L https://github.com/RoaringBitmap/CRoaring/archive/`echo ${CROARING_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
#     cd CRoaring-`echo ${CROARING_VERSION} | sed 's/\\./_/g'`/ && \
#     mkdir -p build && \
#     cd build && \
#     CXXFLAGS="${CXXFLAGS} ${CFLAGS} -Os -std=c++11" \
#     cmake .. -DROARING_BUILD_STATIC=ON -DROARING_DISABLE_NATIVE=ON \
#     -DCMAKE_C_COMPILER=${CROSS_TRIPLE}-cc -DCMAKE_CXX_COMPILER=${CROSS_TRIPLE}-c++ -DROARING_DISABLE_X64=ON && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log && \
#     rm -rf `pwd`
