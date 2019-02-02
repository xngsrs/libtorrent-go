// +build !android

package libtorrent

// #cgo pkg-config: --static libtorrent-rasterbar openssl
// #cgo darwin LDFLAGS: -lm -lstdc++
// #cgo linux CXXFLAGS: -I/usr/include/libtorrent -I/usr/include -I/usr/local/include/libtorrent -I/usr/local/include -Wno-deprecated-declarations -std=c++11
// #cgo linux LDFLAGS: -lm -lstdc++ -ldl -lrt
// #cgo windows CXXFLAGS: -std=c++11 -DIPV6_TCLASS=39 -DSWIGWIN -D_WIN32_WINNT=0x0600 -D__MINGW32__
// #cgo windows LDFLAGS: -static-libgcc -static-libstdc++
import "C"
