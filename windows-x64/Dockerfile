FROM cross-compiler:windows-x64

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
    echo "using gcc : mingw64 : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
    ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} toolset=gcc-mingw64 address-model=64 architecture=x86 link=static variant=release threading=multi target-os=windows threadapi=win32 install 1>log && \
    rm -rf ${HOME}/user-config.jam && \
    rm -rf `pwd`

# Install OpenSSL
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tar.gz && \
    echo "$OPENSSL_SHA256  openssl.tar.gz" | sha256sum -c - && \
    tar -xzf openssl.tar.gz && \
    rm openssl.tar.gz && \
    cd openssl-${OPENSSL_VERSION}/ && \
    CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared mingw64 --prefix=${CROSS_ROOT} 1>log && \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
    make install 1>log && \
    rm -rf `pwd`

# Install SWIG
RUN apt-get update && apt-get install -y automake libpcre3-dev bison yodl

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
  && CC_FOR_TARGET=${CROSS_TRIPLE}-gcc CXX_FOR_TARGET=${CROSS_TRIPLE}-g++ GOOS=windows GOARCH=amd64 CGO_ENABLED=1 ./make.bash --no-clean \
  && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
ENV PATH ${PATH}:/usr/local/go/bin

# Install libtorrent
RUN curl -L https://github.com/ElementumOrg/libtorrent/archive/`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
    cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
    ./autotool.sh && \
    \
    sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
    \
    PKG_CONFIG_PATH=${CROSS_ROOT}/lib/pkgconfig/ \
    CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
    # CFLAGS="${CFLAGS} -Os -lmswsock -DUNICODE -D_UNICODE -DWIN32 -DWIN32_LEAN_AND_MEAN -DIPV6_TCLASS=39 -D_WIN32_WINNT=0x0600" \
    CFLAGS="${CFLAGS} -Os -Wno-psabi -Wno-deprecated-declarations -Wno-sign-compare -Wno-unused-function -Wno-unused-parameter -std=c++11 -lmswsock -DUNICODE -D_UNICODE -DWIN32 -DWIN32_LEAN_AND_MEAN -DIPV6_TCLASS=39 -D_WIN32_WINNT=0x0600" \
    CXXFLAGS="${CXXFLAGS} ${CFLAGS} -fno-strict-aliasing -fvisibility=hidden -DBOOST_ASIO_DISABLE_CONNECTEX -DBOOST_USE_WINAPI_VERSION=0x0600" \
    LIBS="-lmswsock" \
    ./configure \
        --enable-logging=no \
        --enable-static \
        --disable-debug \
        --disable-shared \
        --disable-deprecated-functions \
        --host=${CROSS_TRIPLE} \
        --prefix=${CROSS_ROOT} \
        --with-boost=${CROSS_ROOT} --with-boost-libdir=${CROSS_ROOT}/lib && \
    \
    make -j $(cat /proc/cpuinfo | grep processor | wc -l) && make install && \
    rm -rf `pwd`

WORKDIR /








# FROM cross-compiler:windows-x64

# RUN mkdir -p /build
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
#     echo "using gcc : mingw64 : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" \
#     ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} toolset=gcc-mingw64 address-model=64 architecture=x86 link=static variant=release threading=multi target-os=windows threadapi=win32 install 1>log && \
#     rm -rf ${HOME}/user-config.jam

# # Install OpenSSL
# RUN cd openssl-${OPENSSL_VERSION}/ && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared mingw64 --prefix=${CROSS_ROOT} 1>log && \
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
#   && CC_FOR_TARGET=${CROSS_TRIPLE}-gcc CXX_FOR_TARGET=${CROSS_TRIPLE}-c++ GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} CGO_ENABLED=1 ./make.bash --no-clean \
#   && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
# ENV PATH ${PATH}:/usr/local/go/bin

# # Install libtorrent
# RUN cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
#     ./autotool.sh && \
#     \
#     sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
#     \
#     CC=${CROSS_TRIPLE}-gcc CXX=${CROSS_TRIPLE}-g++ \
#     CFLAGS="${CFLAGS} -Os -std=c++11 -lmswsock -DUNICODE -D_UNICODE -DWIN32 -DWIN32_LEAN_AND_MEAN -DIPV6_TCLASS=39 -D_WIN32_WINNT=0x0600" \
#     CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
#     ./configure \
#         --enable-static \
#         --disable-shared \
#         --disable-deprecated-functions \
#         --host=${CROSS_TRIPLE} \
#         --prefix=${CROSS_ROOT} \
#         --with-boost=${CROSS_ROOT} --with-boost-libdir=${CROSS_ROOT}/lib && \
#     \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) && make install

# RUN rm -rf /build

# WORKDIR /

# FROM cross-compiler:windows-x64

# RUN mkdir -p /build
# WORKDIR /build

# # Fix Boost using wrong archiver / ignoring <archiver> flags
# # https://svn.boost.org/trac/boost/ticket/12573
# # https://github.com/boostorg/build/blob/boost-1.63.0/src/tools/gcc.jam#L972
# RUN mv /usr/bin/ar /usr/bin/ar.orig && \
#     mv /usr/bin/strip /usr/bin/strip.orig && \
#     mv /usr/bin/ranlib /usr/bin/ranlib.orig && \
#     ln -sf /usr/bin/${CROSS_TRIPLE}-ar /usr/bin/ar && \
#     ln -sf /usr/bin/${CROSS_TRIPLE}-strip /usr/bin/strip && \
#     ln -sf /usr/bin/${CROSS_TRIPLE}-ranlib /usr/bin/ranlib

# # Install Boost.System
# ENV BOOST_VERSION 1.67.0
# RUN curl -L https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION}/boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`.tar.bz2/download | tar xj && \
#     cd boost_`echo ${BOOST_VERSION} | sed 's/\\./_/g'`/ && \
#     ./bootstrap.sh --prefix=${CROSS_ROOT} && \
#     echo "using gcc : mingw64 : ${CROSS_TRIPLE}-c++ ;" > ${HOME}/user-config.jam && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" \
#     ./b2 --with-date_time --with-system --with-chrono --with-random --prefix=${CROSS_ROOT} toolset=gcc-mingw64 address-model=64 architecture=x86 link=static variant=release threading=multi target-os=windows threadapi=win32 install 1>log && \
#     rm -rf ${HOME}/user-config.jam && \
#     rm -rf `pwd`

# # Move back ar, strip and ranlib...
# RUN mv /usr/bin/ar.orig /usr/bin/ar && \
#     mv /usr/bin/strip.orig /usr/bin/strip && \
#     mv /usr/bin/ranlib.orig /usr/bin/ranlib

# # Install OpenSSL
# ENV OPENSSL_VERSION 1.1.1a
# ENV OPENSSL_SHA256 fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41
# RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tar.gz && \
#     echo "$OPENSSL_SHA256  openssl.tar.gz" | sha256sum -c - && \
#     tar -xzf openssl.tar.gz && \
#     rm openssl.tar.gz && \
#     cd openssl-${OPENSSL_VERSION}/ && \
#     CXXFLAGS="${CXXFLAGS} -std=c++11" CROSS_COMPILE=${CROSS_TRIPLE}- ./Configure threads no-shared mingw64 --prefix=${CROSS_ROOT} 1>log && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log && \
#     rm -rf `pwd`

# # Install SWIG
# ENV SWIG_VERSION 3.0.12
# RUN curl -L https://github.com/swig/swig/archive/rel-${SWIG_VERSION}.tar.gz | tar xz
# RUN cd swig-rel-${SWIG_VERSION}/ && \
#     ./autogen.sh && \
#     ./configure && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log && \
#     rm -rf `pwd`

# # Install Golang
# ENV GOLANG_VERSION 1.11.4
# ENV GOLANG_SRC_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
# ENV GOLANG_SRC_SHA256 4cfd42720a6b1e79a8024895fa6607b69972e8e32446df76d6ce79801bbadb15

# ENV GOLANG_BOOTSTRAP_VERSION 1.4.3
# ENV GOLANG_BOOTSTRAP_URL https://golang.org/dl/go$GOLANG_BOOTSTRAP_VERSION.src.tar.gz
# ENV GOLANG_BOOTSTRAP_SHA1 486db10dc571a55c8d795365070f66d343458c48

# RUN set -ex \
#   && mkdir -p /usr/local/bootstrap \
#   # && wget -q "$GOLANG_BOOTSTRAP_URL" -O golang.tar.gz \
#   && wget -q "https://storage.googleapis.com/golang/go1.4-bootstrap-20170518.tar.gz" -O golang.tar.gz \
#   # && echo "$GOLANG_BOOTSTRAP_SHA1  golang.tar.gz" | sha1sum -c - \
#   && tar -C /usr/local/bootstrap -xzf golang.tar.gz \
#   && rm golang.tar.gz \
#   && cd /usr/local/bootstrap/go/src \
#   && ./make.bash 1>golang.log 2>golang.err \
#   && export GOROOT_BOOTSTRAP=/usr/local/bootstrap/go \
#   \
#   && wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
#   && echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
#   && tar -C /usr/local -xzf golang.tar.gz \
#   && rm golang.tar.gz \
#   && cd /usr/local/go/src \
#   && ./make.bash 1>golang.log 2>golang.err \
#   \
#   && CC_FOR_TARGET=${CROSS_TRIPLE}-cc CXX_FOR_TARGET=${CROSS_TRIPLE}-c++ GOOS=windows GOARCH=amd64 CGO_ENABLED=1 ./make.bash --no-clean \
#   && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap
# ENV PATH ${PATH}:/usr/local/go/bin

# # Install libtorrent
# # Changes:
# # - define WIN32, _UNICODE, IPV6_TCLASS=39
# # ENV LIBTORRENT_VERSION RC_1_1
# ENV LIBTORRENT_VERSION 434272519fa8cc25a518e6d9ae1161b552d28c04
# RUN curl -L https://github.com/arvidn/libtorrent/archive/`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
#     cd libtorrent-`echo ${LIBTORRENT_VERSION} | sed 's/\\./_/g'`/ && \
#     ./autotool.sh && \
#     \
#     sed -i 's/$PKG_CONFIG openssl --libs-only-/$PKG_CONFIG openssl --static --libs-only-/' ./configure && \
#     \
#     CC=${CROSS_TRIPLE}-cc CXX=${CROSS_TRIPLE}-c++ \
#     CFLAGS="${CFLAGS} -O2 -std=c++11 -lmswsock -DUNICODE -D_UNICODE -DWIN32 -DWIN32_LEAN_AND_MEAN -DIPV6_TCLASS=39 -D_WIN32_WINNT=0x0600" \
#     CXXFLAGS="${CXXFLAGS} ${CFLAGS}" \
#     LIBS="-lmswsock" \
#     ./configure \
#         --enable-static \
#         --disable-shared \
#         --disable-deprecated-functions \
#         --host=${CROSS_TRIPLE} \
#         --prefix=${CROSS_ROOT} \
#         --with-boost=${CROSS_ROOT} --with-boost-libdir=${CROSS_ROOT}/lib && \
#     \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) && make install && \
#     rm -rf `pwd`

# # Install CRoaring
# ENV CROARING_VERSION 6154187fa18728039d757e0f959b120a526e2877
# RUN curl -L https://github.com/RoaringBitmap/CRoaring/archive/`echo ${CROARING_VERSION} | sed 's/\\./_/g'`.tar.gz | tar xz && \
#     cd CRoaring-`echo ${CROARING_VERSION} | sed 's/\\./_/g'`/ && \
#     mkdir -p build && \
#     cd build && \
#     cmake .. -DROARING_BUILD_STATIC=ON && \
#     make -j $(cat /proc/cpuinfo | grep processor | wc -l) 1>log && \
#     make install 1>log && \
#     rm -rf `pwd`

# WORKDIR /
