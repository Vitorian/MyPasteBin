#!/bin/bash
# http://clang.llvm.org/get_started.html
# http://llvm.org/docs/GettingStartedVS.html
# http://libcxx.llvm.org/docs/BuildingLibcxx.html
#
# On builds like this I use to have a BTRFS filesystem mounted on a file/loop with compression on the fly
# Something like
#
#     dd if=/dev/zero of=disk.img bs=1M count=4096
#     mkfs.btrfs -d single -m single --mixed disk.img
#     mkdir disk
#     sudo mount -o loop,compress=lzo disk.img disk
#     chown <your username> disk
#
# Github:
#
# Dont write a clang plugin
#  https://chromium.googlesource.com/chromium/src/+/master/docs/writing_clang_plugins.md#Having-said-that

MIRROR_URL="http://llvm.org"
DEFAULT_CACHE_DIR=$HOME/cache

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version> [installdir] [builddir] [cachedir]"
    echo "Default cache:$DEFAULT_CACHE_DIR"
    echo "Default build:/tmp/build-<version>"
    echo "Default install:$PWD/clang-<version>"
    echo "Current versions:"
    wget -qO- $MIRROR_URL/releases/download.html  | gzip -d | sed -n 's/.*Download LLVM \([0-9\.]*\).*/\1/p' | tr '\n' ' '
    echo
    exit 1
fi

set -exo pipefail

CLANG_VER="$1"

DEFAULT_INSTALL_DIR=$PWD/clang-$CLANG_VER
DEFAULT_BUILD_DIR=/tmp/build-$CLANG_VER

if [ $# -ge 2 ]; then
    INSTALL_DIR=$(readlink -f "$2" )
else
    INSTALL_DIR=$DEFAULT_INSTALL_DIR
fi

if [ $# -ge 3 ]; then
    BUILD_DIR=$(readlink -f "$3" )
else
    BUILD_DIR=$DEFAULT_BUILD_DIR
fi

if [ $# -ge 4 ]; then
    CACHE_DIR=$(reaadlink -f "$4" )
else
    CACHE_DIR=$DEFAULT_CACHE_DIR
fi

CXX_COMPILER=${CXX:-/usr/bin/clang++}
C_COMPILER=${CC:-/usr/bin/clang}
CPU_COUNT=`python -c "import multiprocessing; print multiprocessing.cpu_count() "`
NUMJOBS=${NUMJOBS:-${CPU_COUNT}}

# create build directory
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR
mkdir -p $CACHE_DIR

function patch_ast_printer()
{
    if [ "$CLANG_VER" == "4.0.0" ]; then
      if [ ! -d $BUILD_DIR/clang-$CLANG_VER/tools/clang/examples/ClangASTPrinter ]; then
        cd $BUILD_DIR/clang-$CLANG_VER/tools/clang/examples
        cat <<EOF  >> CMakeLists.txt
add_subdirectory(ClangASTPrinter)
EOF
        git clone https://github.com/HFTrader/ClangASTPrinter.git
      fi
    fi
}

set -x
# build clang
cd $BUILD_DIR
if [ ! -e $BUILD_DIR/clang.$CLANG_VER.done ]; then
    CLANG_DIR="clang-${CLANG_VER}"
    #PACKAGES="cfe llvm compiler-rt clang-tools-extra libcxx libcxxabi libunwind lld lldb openmp polly"
    PACKAGES="cfe llvm compiler-rt clang-tools-extra libunwind lld lldb openmp polly"
    if [ ! -e llvm.untar.$CLANG_VER.done ]; then
      for pkg in $PACKAGES; do
        TARFILE="${pkg}-${CLANG_VER}.src.tar.xz"
        UNTARDIR="${pkg}-$CLANG_VER"
        if [ ! -e "$CACHE_DIR/$TARFILE" ]; then
            wget "$MIRROR_URL/releases/$CLANG_VER/$TARFILE" -o "$CACHE_DIR/$TARFILE"
        fi
        rm -rf "$UNTARDIR"
        rm -rf "$UNTARDIR.src"
        tar xaf "$CACHE_DIR/$TARFILE"
      done

      # move to respective places
      rm -rf $CLANG_DIR
      mv -v llvm-${CLANG_VER}.src $CLANG_DIR
      mv -v cfe-${CLANG_VER}.src $CLANG_DIR/tools/clang
      mv -v clang-tools-extra-${CLANG_VER}.src $CLANG_DIR/tools/clang/tools/extra
      mv -v compiler-rt-${CLANG_VER}.src $CLANG_DIR/projects/compiler-rt
      #mv -v libcxx-${CLANG_VER}.src $CLANG_DIR/projects/libcxx
      #mv -v libcxxabi-${CLANG_VER}.src $CLANG_DIR/projects/libcxxabi
      mv -v polly-${CLANG_VER}.src $CLANG_DIR/tools/polly
      mv -v libunwind-${CLANG_VER}.src $CLANG_DIR/projects/libunwind
      mv -v openmp-${CLANG_VER}.src $CLANG_DIR/projects/openmp
      mv -v lld-${CLANG_VER}.src $CLANG_DIR/tools/lld
      mv -v lldb-${CLANG_VER}.src $CLANG_DIR/tools/lldb
      ( patch_ast_printer )
      touch llvm.untar.$CLANG_VER.done
    fi

    # cmake
    rm -rf $BUILD_DIR/build && \
    mkdir -p $BUILD_DIR/build && \
    cd $BUILD_DIR/build && \
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
          -DCMAKE_C_COMPILER=$C_COMPILER \
          -DCMAKE_C_FLAGS=-DLLVM_ENABLE_DUMP \
          -DCMAKE_CXX_FLAGS=-DLLVM_ENABLE_DUMP \
          -DLLVM_ENABLE_ASSERTIONS=ON \
          -DLIBCXX_ENABLE_EXCEPTIONS=ON \
          -DLLVM_BUILD_TESTS=OFF \
          -DLLVM_INCLUDE_TESTS=OFF \
          -DLLVM_INCLUDE_DOCS=OFF \
          -DLLVM_BUILD_EXAMPLES=OFF \
          -DLLVM_INCLUDE_EXAMPLES=ON \
          -DLLVM_CCACHE_BUILD=ON \
          -DLLVM_TARGETS_TO_BUILD=X86 \
          -DLLVM_BUILD_TOOLS=ON \
          -DLLVM_INCLUDE_TOOLS=ON \
          -DCLANG_BUILD_TOOLS=ON \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_INSTALL_DO_STRIP=OFF \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -G Ninja \
          $BUILD_DIR/$CLANG_DIR && \
    time cmake --build . -- -j$NUMJOBS && \
    cmake --build . --target install && \
    touch $BUILD_DIR/clang.$CLANG_VER.done
fi

# build clang
cd $BUILD_DIR
if [ ! -e $BUILD_DIR/facebook.$CLANG_VER.done ]; then
    TARFILE=facebook-clang-plugins.tgz
    if [ ! -e "$CACHE_DIR/$TARFILE" ]; then
        git clone https://github.com/facebook/facebook-clang-plugins.git
        tar caf $CACHE_DIR/$TARFILE facebook-clang-plugins
        rm -rf facebook-clang-plugins
    fi
    rm -rf facebook-clang-plugins
    tar xaf "$CACHE_DIR/$TARFILE"

    cd facebook-clang-plugins
    CC=$C_COMPILER \
      CXX=$CXX_COMPILER \
      CLANG_PREFIX=$INSTALL_DIR \
      make -C libtooling test
    touch $BUILD_DIR/facebook.$CLANG_VER.done
fi

exit 0
