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
#     sudo mount -o loop,compress=zlib:6 disk.img disk
#     chown <your username> disk
#
# Github:
#
# Dont write a clang plugin
#  https://chromium.googlesource.com/chromium/src/+/master/docs/writing_clang_plugins.md#Having-said-that

TODAY=$(date +%Y%m%d)

function download_clang()
{
    # check if it is already downloaded
    if [ ! -e "${CACHE_DIR}/clang-${CLANG_VER}.tar.xz" ]; then
        # check if it is a git request
        if [ "$CLANG_VER" == "$TODAY" ]; then
            cd $CACHE_DIR
            if [ -d  llvm-project ]; then
                # pull out the main branch
                cd llvm-project
                git checkout main 
                git pull --recurse-submodules
            else
                # checkout the entire git project (slooooow)
                git clone --recursive https://github.com/llvm/llvm-project.git llvm-project
            fi

            # copy all files but the .git structure (gigantic)
            cd $BUILD_DIR
            rm -rf clang-${CLANG_VER}
            mkdir -p clang-${CLANG_VER}
            rsync -a --exclude=.git $CACHE_DIR/llvm-project/ clang-${CLANG_VER}/
            tar -c -I "xz -9 -T$NUMJOBS" -f ${CACHE_DIR}/clang-${CLANG_VER}.tar.xz clang-${CLANG_VER}
            # cleanup
            rm -rf clang-${CLANG_VER}
        else 
            # this is a standard released version
            if [ ! -e "${CACHE_DIR}/clang-${CLANG_VER}.tar.xz" ]; then
                # download it from the official github release URL
                URL="https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${CLANG_VER}.tar.gz" 
                cd $CACHE_DIR
                wget --no-check-certificate "$URL" -O clang-${CLANG_VER}.tar.gz
                # recompress as original tarball has a weird prefix and is in gzip format
                tar xaf clang-${CLANG_VER}.tar.gz
                rm -rf clang-${CLANG_VER}
                mv llvm-project-llvmorg-${CLANG_VER} clang-${CLANG_VER}
                tar -c -I "xz -9 -T$NUMJOBS" -f clang-$CLANG_VER.tar.xz clang-${CLANG_VER}
                # cleanup old downloaded file and temp folder
                rm clang-${CLANG_VER}.tar.gz
                rm -rf clang-${CLANG_VER}
            fi
        fi
    fi
    # Now that we have donwloaded and corrected the file, just untar
    cd ${BUILD_DIR}
    rm -rf clang-${CLANG_VER}
    tar -x -a -f $CACHE_DIR/clang-${CLANG_VER}.tar.xz
}

CLANG_VER=${1:-"<version>"}
if [ "$CLANG_VER" = "git" ]; then
    CLANG_VER=$TODAY
fi

if [ -e $HOME/.build_clang ]; then
    echo "Sourcing $HOME/.build_clang"
    source $HOME/.build_clang
fi

# Set all environment variables with defaults
BUILD_DIR=${BUILD_DIR:-"/tmp"}
CACHE_DIR=${CACHE_DIR:-"$HOME/cache"}
INSTALL_DIR=${INSTALL_DIR:-"$HOME/bin/clang-${CLANG_VER}"}
CXX_COMPILER=${CXX:-$(which clang++) }
C_COMPILER=${CC:-$(which clang) }
LINKER=${LINKER:-$(which clang++) }
NUMCPUS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
NUMJOBS="${NUMJOBS:-$NUMCPUS}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version>"
    echo "  <version> can be one of the current released versions (see list below)," 
    echo "     a previously saved date as 20220914 or 'git' for the current latest trunk"
    echo "Optional environment variables to set:"
    echo "  CACHE_DIR=$CACHE_DIR"
    echo "  BUILD_DIR=$BUILD_DIR"
    echo "  INSTALL_DIR=$INSTALL_DIR"
    echo "  CXX_COMPILER=$CXX_COMPILER"
    echo "  C_COMPILER=$C_COMPILER"
    echo "  LINKER=$LINKER"
    echo "If there is a file in $HOME/.build_clang it will be sourced for defaults"
    echo "Current versions:"
    wget -qO- http://llvm.org/releases/download.html  | gzip -d | \
         sed -n 's/.*Download LLVM \([0-9\.]*\).*/\1/p' | tr '\n' ' '
    echo
    exit 1
fi

echo "Optional variables set:"
echo "  CACHE_DIR=$CACHE_DIR"
echo "  BUILD_DIR=$BUILD_DIR"
echo "  INSTALL_DIR=$INSTALL_DIR"
echo "  CXX_COMPILER=$CXX_COMPILER"
echo "  C_COMPILER=$C_COMPILER"
echo "  LINKER=$LINKER"

# Stop script on failure
set -exo pipefail

# create build, cache and install directories
rm -rf "${BUILD_DIR}/clang-${CLANG_VER}" 
mkdir -p "$BUILD_DIR/clang-${CLANG_VER}"
mkdir -p $INSTALL_DIR
mkdir -p $CACHE_DIR

CXXOPTS="-O2 -DLLVM_ENABLE_DUMP -I$INSTALL_DIR/include"
CXXLINK="-L$INSTALL_DIR/lib -L$INSTALL_DIR/lib64 -Wl,-rpath,$INSTALL_DIR/lib64 -Wl,-rpath,$INSTALL_DIR/lib"
CCOPTS="-DLLVM_ENABLE_DUMP"
CCLINK="-L$INSTALL_DIR/lib -L$INSTALL_DIR/lib64 -Wl,-rpath,$INSTALL_DIR/lib64 -Wl,-rpath,$INSTALL_DIR/lib"

# build clang
download_clang        

# configure
cd "$BUILD_DIR/clang-${CLANG_VER}"
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
    -DCMAKE_PREFIX_PATH=$INSTALL_DIR \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_C_FLAGS:STRING="$CXXOPTS" \
    -DCMAKE_CXX_FLAGS:STRING="$CCOPTS" \
    -DCMAKE_CXX_LINK_FLAGS="$CXXLINK" \
    -DCMAKE_C_LINK_FLAGS="$CCLINK" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DLIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY=OFF \
    -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLLVM_ENABLE_SPHINX=OFF \
    -DLLVM_ENABLE_DOXYGEN=OFF \
    -DLLVM_ENABLE_THREADS:BOOL=ON \
    -DLLVM_ENABLE_PIC:BOOL=ON \
    -DLLVM_ENABLE_FFI:BOOL=ON \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
    -DLLVM_INSTALL_UTILS=ON \
    -DLLVM_TARGETS_TO_BUILD="host;AMDGPU;BPF" \
    -DLLVM_PARALLEL_COMPILE_JOBS=$NUMJOBS \
    -DLLVM_PARALLEL_LINK_JOBS=$NUMJOBS \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_TOOLS=ON \
    -DLLVM_INCLUDE_TESTS=ON \
    -DLLVM_INCLUDE_BENCHMARKS=ON \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_BUILD_TOOLS=ON \
    -DLLVM_ENABLE_PROJECTS="clang;lld;lldb;polly;clang-tools-extra;bolt;mlir" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind;libc" \
    -DLLVM_USE_PERF=OFF \
    -DLLVM_CCACHE_BUILD=OFF \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_ENABLE_EH=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    -DCLANG_BUILD_TOOLS=ON \
    -DCLANG_VENDOR="Vitorian LLC" \
    -G Ninja \
    "../llvm"

# build full throttle
time cmake --build . -- -j$NUMJOBS

# install
cmake --build . --target install/strip -- -j$NUMJOBS

cat <<EOF > $INSTALL_DIR/env_vars.sh
PATH=$INSTALL_DIR/bin:$PATH
LD_LIBRARY_PATH=$INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
MAN_PATH=$INSTALL_DIR/share/man:$MAN_PATH
EOF

