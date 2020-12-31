PROJECT = elementumorg
NAME = libtorrent-go
GO_PACKAGE = github.com/ElementumOrg/$(NAME)
CC = cc
CXX = c++
PKG_CONFIG = pkg-config
DOCKER = docker
DOCKER_IMAGE = $(NAME)
PLATFORMS = \
	android-arm \
	android-arm64 \
	android-x64 \
	android-x86 \
	linux-armv6 \
	linux-armv7 \
	linux-arm64 \
	linux-x64 \
	linux-x86 \
	windows-x64 \
	windows-x86 \
	darwin-x64 \
	darwin-x86

BOOST_VERSION = 1.72.0
BOOST_VERSION_FILE = $(shell echo $(BOOST_VERSION) | sed s/\\./_/g)
# BOOST_SHA256 = 59c9b274bc451cf91a9ba1dd2c7fdcaf5d60b1b3aa83f2c9fa143417cc660722

OPENSSL_VERSION = 1.1.1f
# OPENSSL_SHA256 = f6fb3079ad15076154eda9413fed42877d668e7069d9b87396d0804fdb3f4c90

SWIG_VERSION = b6c2438d7d7aac5711376a106a156200b7ff1056

GOLANG_VERSION = 1.15.4
GOLANG_SRC_URL = https://golang.org/dl/go$(GOLANG_VERSION).src.tar.gz
GOLANG_SRC_SHA256 = 063da6a9a4186b8118a0e584532c8c94e65582e2cd951ed078bfd595d27d2367

GOLANG_BOOTSTRAP_VERSION = 1.4-bootstrap-20170531
GOLANG_BOOTSTRAP_URL = https://dl.google.com/go/go$(GOLANG_BOOTSTRAP_VERSION).tar.gz
GOLANG_BOOTSTRAP_SHA256 = 49f806f66762077861b7de7081f586995940772d29d4c45068c134441a743fa2

LIBTORRENT_VERSION = 1.1.14

include platform_host.mk

ifneq ($(CROSS_TRIPLE),)
	CC := $(CROSS_TRIPLE)-$(CC)
	CXX := $(CROSS_TRIPLE)-$(CXX)
endif

include platform_target.mk

ifeq ($(TARGET_ARCH), x86)
	GOARCH = 386
else ifeq ($(TARGET_ARCH), x64)
	GOARCH = amd64
else ifeq ($(TARGET_ARCH), arm)
	GOARCH = arm
	GOARM = 6
else ifeq ($(TARGET_ARCH), armv6)
	GOARCH = arm
	GOARM = 6
else ifeq ($(TARGET_ARCH), armv7)
	GOARCH = arm
	GOARM = 7
	PATH_SUFFIX = v7
	PKGDIR = -pkgdir /go/pkg/linux_armv7
else ifeq ($(TARGET_ARCH), arm64)
	GOARCH = arm64
	GOARM =
endif

ifeq ($(TARGET_OS), windows)
	GOOS = windows
else ifeq ($(TARGET_OS), darwin)
	GOOS = darwin
else ifeq ($(TARGET_OS), linux)
	GOOS = linux
	CC = gcc
	CXX = g++
else ifeq ($(TARGET_OS), android)
	GOOS = android
	ifeq ($(TARGET_ARCH), armv6)
		GOARM = 7
	else
		GOARM =
	endif
	GO_LDFLAGS += -flto -extldflags=-pie
endif

ifneq ($(CROSS_ROOT),)
	CROSS_CFLAGS = -I$(CROSS_ROOT)/include -I$(CROSS_ROOT)/$(CROSS_TRIPLE)/include
	CROSS_LDFLAGS = -L$(CROSS_ROOT)/lib
	PKG_CONFIG_PATH = $(CROSS_ROOT)/lib/pkgconfig
endif

LIBTORRENT_CFLAGS = $(CFLAGS) $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) --cflags libtorrent-rasterbar)
LIBTORRENT_LDFLAGS = $(LDFLAGS) $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKG_CONFIG) --static --libs libtorrent-rasterbar)
DEFINE_IGNORES = __STDC__|_cdecl|__cdecl|_fastcall|__fastcall|_stdcall|__stdcall|__declspec
CC_DEFINES = $(shell echo | $(CC) -dM -E - | grep -v -E "$(DEFINE_IGNORES)" | sed -E "s/\#define[[:space:]]+([a-zA-Z0-9_()]+)[[:space:]]+(.*)/-D\1="\2"/g" | tr '\n' ' ')

ifeq ($(TARGET_OS), windows)
	CC_DEFINES += -DSWIGWIN
	CC_DEFINES += -D_WIN32_WINNT=0x0600
	ifeq ($(TARGET_ARCH), x64)
		CC_DEFINES += -DSWIGWORDSIZE32
	endif
else ifeq ($(TARGET_OS), darwin)
	CC = $(CROSS_ROOT)/bin/$(CROSS_TRIPLE)-clang
	CXX = $(CROSS_ROOT)/bin/$(CROSS_TRIPLE)-clang++
	CC_DEFINES += -DSWIGMAC
else ifeq ($(TARGET_OS), android)
	CC = $(CROSS_ROOT)/bin/$(CROSS_TRIPLE)-clang
	CXX = $(CROSS_ROOT)/bin/$(CROSS_TRIPLE)-clang++
	GO_LDFLAGS = -flto -extldflags=-pie
	ifeq ($(TARGET_ARCH), arm64)
		CC_DEFINES = -DSWIGWORDSIZE64
	endif
else ifeq ($(TARGET_OS), linux)
	GO_LDFLAGS += -flto
	ifeq ($(TARGET_ARCH), arm64)
		CC_DEFINES = -DSWIGWORDSIZE64
	endif
endif


OUT_PATH = $(shell go env GOPATH)/pkg/$(GOOS)_$(GOARCH)$(PATH_SUFFIX)
OUT_LIBRARY = $(OUT_PATH)/$(GO_PACKAGE).a

.PHONY: $(PLATFORMS)

all:
	for i in $(PLATFORMS); do \
		$(MAKE) $$i; \
	done

$(PLATFORMS):
ifeq ($@, all)
	$(MAKE) all
else
	$(DOCKER) run --rm -v $(GOPATH):/go -v $(shell pwd):/go/src/$(GO_PACKAGE) -w /go/src/$(GO_PACKAGE) -e GOPATH=/go $(DOCKER_IMAGE):$@ make re;
endif

build:
	SWIG_FLAGS='$(CC_DEFINES) $(LIBTORRENT_CFLAGS)' \
	CC=$(CC) CXX=$(CXX) \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CGO_ENABLED=1 \
	GOOS=$(GOOS) GOARCH=$(GOARCH) GOARM=$(GOARM) \
	PATH=.:$$PATH \
	go install -v -ldflags '$(GO_LDFLAGS)' $(PKGDIR)
	
clean:
	rm -rf $(OUT_LIBRARY)

re: clean build

retest:
	$(DOCKER) run --rm -v $(GOPATH):/go -v $(shell pwd):/go/src/$(GO_PACKAGE) -w /go/src/$(GO_PACKAGE) -e GOPATH=/go $(DOCKER_IMAGE):linux-armv7 make runtest;

runtest:
	CC=${CC} CXX=$(CXX) \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CGO_ENABLED=1 \
	GOOS=$(GOOS) GOARCH=$(GOARCH) GOARM=$(GOARM) \
	PATH=.:$$PATH \
	cd test; go run -x test.go; cd ..

env:
	$(DOCKER) build \
		--build-arg BOOST_VERSION=$(BOOST_VERSION) \
		--build-arg BOOST_VERSION_FILE=$(BOOST_VERSION_FILE) \
		--build-arg BOOST_SHA256=$(BOOST_SHA256) \
		--build-arg OPENSSL_VERSION=$(OPENSSL_VERSION) \
		--build-arg OPENSSL_SHA256=$(OPENSSL_SHA256) \
		--build-arg SWIG_VERSION=$(SWIG_VERSION) \
		--build-arg SWIG_SHA256=$(SWIG_SHA256) \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		--build-arg GOLANG_SRC_URL=$(GOLANG_SRC_URL) \
		--build-arg GOLANG_SRC_SHA256=$(GOLANG_SRC_SHA256) \
		--build-arg GOLANG_BOOTSTRAP_VERSION=$(GOLANG_BOOTSTRAP_VERSION) \
		--build-arg GOLANG_BOOTSTRAP_URL=$(GOLANG_BOOTSTRAP_URL) \
		--build-arg GOLANG_BOOTSTRAP_SHA256=$(GOLANG_BOOTSTRAP_SHA256) \
		--build-arg LIBTORRENT_VERSION=$(LIBTORRENT_VERSION) \
		-t $(DOCKER_IMAGE):$(PLATFORM) \
		-f docker/$(PLATFORM).Dockerfile docker

envs:
	for i in $(PLATFORMS); do \
		$(MAKE) env PLATFORM=$$i; \
	done

pull:
	docker pull $(PROJECT)/cross-compiler:$(PLATFORM)
	docker tag $(PROJECT)/cross-compiler:$(PLATFORM) cross-compiler:$(PLATFORM)

pull-all:
	for i in $(PLATFORMS); do \
		PLATFORM=$$i $(MAKE) pull; \
	done

pull-libtorrent:
	docker pull $(PROJECT)/libtorrent-go:$(PLATFORM)
	docker tag $(PROJECT)/libtorrent-go:$(PLATFORM) libtorrent-go:$(PLATFORM)

pull-libtorrent-all:
	for i in $(PLATFORMS); do \
		PLATFORM=$$i $(MAKE) pull-libtorrent; \
	done

push:
	docker tag libtorrent-go:$(PLATFORM) $(PROJECT)/libtorrent-go:$(PLATFORM)
	docker push $(PROJECT)/libtorrent-go:$(PLATFORM)

push-all:
	for i in $(PLATFORMS); do \
		PLATFORM=$$i $(MAKE) push; \
	done
