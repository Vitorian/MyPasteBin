#!/bin/bash
set -e
set -x
INSTALL_DIR=$PWD/install
CACHE_DIR=$HOME/tests/cache
MONGOC_URL=https://github.com/mongodb/mongo-c-driver/releases/download/
MONGOC_VERSION=1.15.1
MONGOCXX_URL=https://github.com/mongodb/mongo-cxx-driver/archive/debian/
MONGOCXX_VERSION=3.4.0-1
BUILDTYPE=release
SHAREDLIBS=on
STATICLIBS=off
CXX=g++
CC=gcc
NUMJOBS=4
GENERATOR="Unix Makefiles"

if false; then
    pacman -Su --noconfirm \
	   python2 python3 base-devel git wget p7zip \
	   perl nano emacs  \
	   mingw64/mingw-w64-x86_64-{toolchain,gcc,clang,cmake,boost,ninja} \
	   mingw64/mingw-w64-x86_64-{openssl,cyrus-sasl,snappy} \
	   mingw64/mingw-w64-x86_64-{qt5-static,qt-creator}
fi

mkdir -p $CACHE_DIR

#########################################################################3333
# MONGO-C DRIVER

if [ ! -f mongo-c-driver.done ]
then
    if [ ! -f $CACHE_DIR/mongo-c-driver-$MONGOC_VERSION.tar.gz ]; then
	wget $MONGOC_URL/$MONGOC_VERSION/mongo-c-driver-$MONGOC_VERSION.tar.gz \
	     -O $CACHE_DIR/mongo-c-driver-$MONGOC_VERSION.tar.gz
    fi

    rm -rf mongo-c-driver-$MONGOC_VERSION
    tar xaf $CACHE_DIR/mongo-c-driver-$MONGOC_VERSION.tar.gz
    pushd mongo-c-driver-$MONGOC_VERSION
    mkdir -p tmp
    cd tmp
    cmake \
	-DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIR \
	-DCMAKE_BUILD_TYPE:STRING=$BUILDTYPE \
	-DCMAKE_C_COMPILER:FILEPATH=$CC \
	-DCMAKE_C_FLAGS:STRING="-D__USE_MINGW_ANSI_STDIO=1" \
	-DENABLE_AUTOMATIC_INIT_AND_CLEANUP:BOOL=OFF \
	-DENABLE_EXTRA_ALIGNMENT:BOOL=OFF \
	-DENABLE_COVERAGE:BOOL=OFF \
	-DENABLE_EXAMPLES:BOOL=OFF \
	-DENABLE_TESTS:BOOL=OFF \
	-DENABLE_ZSTD:BOOL=OFF \
	-DENABLE_STATIC:BOOL=$STATICLIBS \
	-DBUILD_SHARED_LIBS:BOOL=$SHAREDLIBS \
	-G "$GENERATOR" ..
    cmake --build . --parallel $NUMJOBS --target install
    popd
    rm -rf mongo-c-driver-$MONGOC_VERSION
    touch mongo-c-driver.done
fi

#########################################################################3333
# MONGO-CXX DRIVER

if [ ! -f mongo-cxx-driver.done ]
then
    if [ ! -f $CACHE_DIR/mongo-cxx-driver-$MONGOCXX_VERSION.tar.gz ]
    then
	wget $MONGOCXX_URL/$MONGOCXX_VERSION.tar.gz \
	     -O $CACHE_DIR/mongo-cxx-driver-$MONGOCXX_VERSION.tar.gz
    fi

    rm -rf mongo-cxx-driver-debian-$MONGOCXX_VERSION
    tar xaf $CACHE_DIR/mongo-cxx-driver-$MONGOCXX_VERSION.tar.gz
    pushd mongo-cxx-driver-debian-$MONGOCXX_VERSION
    mkdir -p tmp
    cd tmp
    cmake \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
	  -DCMAKE_PREFIX_PATH=$INSTALL_DIR \
	  -DCMAKE_BUILD_TYPE:STRING=$BUILDTYPE \
	  -DBSONCXX_POLY_USE_BOOST=1 \
	  -DCMAKE_C_COMPILER:FILEPATH=$CC \
	  -DCMAKE_CXX_COMPILER:FILEPATH=$CXX \
	  -DBUILD_SHARED_LIBS:BOOL=$SHAREDLIBS \
	  -DMONGOCXX_ENABLE_SLOW_TESTS:BOOL=OFF \
	  -DMONGOCXX_ENABLE_SSL:BOOL=ON \
	  -DCMAKE_C_FLAGS="-D__USE_MINGW_ANSI_STDIO=1" \
	  -G "$GENERATOR" ..
    cmake --build . --parallel $NUMJOBS --target install
    popd
    touch mongo-cxx-driver.done
    rm -rf mongo-cxx-driver-debian-$MONGOCXX_VERSION
fi




