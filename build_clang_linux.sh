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
    CACHE_DIR=$(readlink -f "$4" )
else
    CACHE_DIR=$DEFAULT_CACHE_DIR
fi

CXX_COMPILER=${CXX:-$(which 'clang++'||which 'g++') }
C_COMPILER=${CC:-$(which clang||which gcc) }

NUMCPUS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
NUMJOBS="${NUMJOBS:-$NUMCPUS}"

# create build directory
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR
mkdir -p $CACHE_DIR

function patch_sources()
{
    #mangle_suppress_errors.patch
    cat <<EOF | base64 -d | gzip -d | patch -p 2
H4sIACpvelwCA+2V227aQBCGr8tTTJHaQsFgCGDj9BBCuIjUJFWgVe6sxd7Aqvauu7vOQVXfveNT
AEECpFXVi84NaHc8+8//edY+u74G43Z67MdgRC0wZAykGQQ3YVMLEaimFxA+awZs2hyMJ81TTTiL
wzNcC2jDiyKY7pFcMgxjr+ov2mbLNkzLODCh1XbaHadjN8wiAHdMs1Sr1fZSkRTtG2bbMDtgWk67
7XQ6DatvWq2e1bKxqI1Fj44AD23ZdQtq6e8B4NKNYD4Mr67OSUizgtJxwvTPORX8K/W0kJP7qLRz
Jq14gisNJzSi3KdcL3bg7aQKP0oGwAkjMy6UZp4a8RnjFF4nSwrew1BwTe90Y0Z1ulSpHiZPxFyx
Gad++ujpCSamu0naMFZahNl6JclNYu0ExxlJKWS9SCh7hHOhIWsB9Jwp8AvNwLEluEmVg06k31Nd
zpRk517SSEhdmRgfUMFAa8mmsaafhFep1nONmF4DuIg1vHsHZdeN+ZxwP6C+u2pY+bAEP3M+/YOM
j93fymcwkN6818lqlXbO/I9pZ0wbfVui1e116jbS6nZ7GS1JvVgq6pRS6ewaKi/P4yDA2rmhSTSb
MFAwJT4QlffzYAIwVQem3+A+1ZpiU6gFPEnUnPFZ41HXtnJJYlc2W5lsjQIa0ijA0btIUqUY8kpB
vTLLC2UrrEYpqxHmr2JanI6csqSxDvUwIEolL32lurQhYunRSzyaVjK+SWxivNCVgE2igNs3M7iW
tQ7XI4pCItFxjhkn8h5t95nGKiS4iKgk+LKkwpyC+3OQrQFb9es3uJU/OiBynXDL9BxEyPCF8yFk
PvqSbXIfcpBTmnP0H6jtxex5xDbxetruguFUUvLtMANp413aQ5C21do0pSnKL6PJxMUZH2saOYtR
/bfnbMOU4VXoKuxhadweG7Ply+8xs3NHClcBrdOx5IWx/V76sbKt7tPGIiJ+9vmSfo+ZpP6Yhf4g
QIecv2Pzsps7Wb7BV9edxizQjLsijFyZd+IqbMUlSS9/yPCn7Fqn8AvyHiPm6woAAA==
EOF
    #err_ret_local_block.patch
    cat <<EOF | base64 -d | gzip -d | patch -p 2
H4sIAGRvelwCA6WPz0/CMBTH7/wV7+bI6NaJ/JqEoIEDCQeDxisp2xs0du3SFpAY/3dbcAlIPBjf
4XVr3ufz+iWEAIuF2JWxVUqYOBNMrmPBV/EzluzYZpLbKKsqcHVLkz6hfZL0IOmkST/tdCNaFxDa
o7QRhiGs/uYcEJqQNgXaTdu9tH3tHI+BdAd3tNWD8HgOYDxuwHkNhzCVlttDtEb7cqgwaJIRNwss
UKPM8HTlxyaLKRm5oQlmImheWbhhwyemy1em/cQouJw/KThbL1wqvK/xT0BhEHgBgRc8CpW9Td8r
PQrmDvlokHqDRwPf5iprQe4+0hS1Xmq0SwcxsVx59ueasObjGCZK3liwG632rnMDjlca8q3mcg0z
6RKD3kpzCf1zr5vbagkFczF/S/2Q53rOVijOk8PVy/fMifYblN9S/2oGwoNQaFW6H2OZxRKlBXQq
NIYrGV2o5sh2HrQbBJOpCiFXaLweZQ7cGhC8QMtLjBpfBU/LtecCAAA=
EOF
}

function patch_install()
{
    #attr_dump_cpu_cases_compilation_fix.patch
    cat <<EOF | base64 -d | gzip -d | patch -p 1
H4sIAJZvelwCA72OQU+DMBxHz/IpfvFgmFhoa1il4EIz7prgvHeVKRGBQDkZv7ttpslu6sU26b9J
X18eIQQ6aXvTLU9NYjrdPyeqfkiUtVO1vI2xezrjlN0QRglloEJyIdPrOBU05UKsGQgVlAZRFGH/
d5GIBeNOtM7El6gsQTjPrliKyM8MZRnAr/3U6Nfc3z/8YfTcQDu9lNv7XdXOo7bmReI9IJ42Qz9b
6MUOuKwVbj1vixPSl21CtcqP/GGYEJ58unjUHSRqRTZmXOZwtTpywF2NosC52244Kv9FXj02pj20
5ue8b/If83aV2nqz7q3v+wTK8eBHFAIAAA==
EOF
}

# build clang
cd $BUILD_DIR
if [ ! -e $BUILD_DIR/clang.$CLANG_VER.done ]; then

    CLANG_DIR="$BUILD_DIR/clang"
    #PACKAGES="cfe llvm compiler-rt clang-tools-extra libcxx libcxxabi libunwind lld lldb openmp polly"
    PACKAGES="cfe llvm compiler-rt clang-tools-extra libunwind lld lldb openmp polly"
    for pkg in $PACKAGES; do
        TARFILE="${pkg}-${CLANG_VER}.src.tar.xz"
        UNTARDIR="${pkg}-$CLANG_VER"
        if [ ! -e "$CACHE_DIR/$TARFILE" ]; then
            wget "$MIRROR_URL/releases/$CLANG_VER/$TARFILE" -O "$CACHE_DIR/$TARFILE"
        fi
        rm -rf "$UNTARDIR"
        rm -rf "$UNTARDIR.src"
        tar xaf "$CACHE_DIR/$TARFILE"
    done

    if [ ! -e "$CACHE_DIR/cppinsights.tar.xz" ]; then
          git clone -b "v_0.2" https://github.com/andreasfertig/cppinsights.git
          tar caf "$CACHE_DIR/cppinsights.tar.xz" cppinsights
    fi

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

    #rm -rf cppinsights
    #tar xaf "$CACHE_DIR/cppinsights.tar.xz"
    #mv -v cppinsights $CLANG_DIR/tools/clang/tools/extra
    #echo "add_subdirectory(cppinsights)" >> $CLANG_DIR/tools/clang/tools/extra/CMakeLists.txt

    # for facebook plugins to work
    pushd $CLANG_DIR
    patch_sources
    popd

    # configure
    rm -rf $BUILD_DIR/build
    mkdir -p $BUILD_DIR/build
    cd $BUILD_DIR/build
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
          -DCMAKE_C_COMPILER=$C_COMPILER \
          -DCMAKE_C_FLAGS=-DLLVM_ENABLE_DUMP \
          -DCMAKE_CXX_FLAGS=-DLLVM_ENABLE_DUMP \
          -DLLVM_INCLUDE_TOOLS=ON \
          -DLLVM_INCLUDE_TESTS=OFF \
          -DLLVM_INCLUDE_DOCS=OFF \
          -DLLVM_INCLUDE_EXAMPLES=ON \
          -DLLVM_BUILD_EXAMPLES=OFF \
          -DLLVM_BUILD_EXTERNAL_COMPILER_RT=On \
          -DLLVM_BUILD_TESTS=OFF \
          -DLLVM_BUILD_TOOLS=ON \
          -DLLVM_ENABLE_ASSERTIONS=Off \
          -DLLVM_ENABLE_EH=ON \
          -DLLVM_ENABLE_RTTI=ON \
          -DLLVM_ENABLE_CXX1Y=ON \
          -DLLVM_TARGETS_TO_BUILD=all \
          -DLLVM_CCACHE_BUILD=ON \
          -DCLANG_BUILD_TOOLS=ON \
          -DCLANG_VENDOR="Vitorian LLC" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_SHARED_LINKER_FLAGS="-lstdc++ -fPIC" \
          -G Ninja \
          "$CLANG_DIR"

    # build full throttle
    time cmake --build . -- -j$NUMJOBS

    # in case it fails with some memory bs, retry with one CPU
    cmake --build . -- -j1

    # install
    cmake --build . --target install
    pushd $INSTALL_DIR
    patch_install
    popd

    # done, signalize
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
    CC=$INSTALL_DIR/bin/clang \
    CXX=$INSTALL_DIR/bin/clang++ \
    CLANG_PREFIX=$INSTALL_DIR \
      make -C libtooling -j $NUMJOBS
    touch $BUILD_DIR/facebook.$CLANG_VER.done
fi

exit 0
