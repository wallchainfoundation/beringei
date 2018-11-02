#!/bin/bash
set -e

FB_VERSION="2018.10.22.00"
ZSTD_VERSION="1.3.7"

echo "This script configures ubuntu with everything needed to run beringei."
echo "It requires that you run it as root. sudo works great for that."

apt update

apt install --yes \
    autoconf \
    autoconf-archive \
    automake \
    binutils-dev \
    bison \
    clang-format-3.9 \
    cmake \
    flex \
    g++ \
    git \
    gperf \
    libboost-all-dev \
    libcap-dev \
    libdouble-conversion-dev \
    libevent-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libjemalloc-dev \
    libkrb5-dev \
    liblz4-dev \
    liblzma-dev \
    libnuma-dev \
    libsasl2-dev \
    libsnappy-dev \
    libssl-dev \
    libtool \
    make \
    pkg-config \
    scons \
    wget \
    zip \
    zlib1g-dev

ready_destdir() {
        if [[ -e ${2} ]]; then
                echo "Moving aside existing $1 directory.."
                mv -v "$2" "$2.bak.$(date +%Y-%m-%d)"
        fi
}

mkdir -pv /usr/local/facebook-${FB_VERSION}
ln -sfT /usr/local/facebook-${FB_VERSION} /usr/local/facebook

export LDFLAGS="-L/usr/local/facebook/lib -Wl,-rpath=/usr/local/facebook/lib"
export CPPFLAGS="-I/usr/local/facebook/include"
export CXXFLAGS=${CPPFLAGS}

cd /tmp

wget -O /tmp/folly-${FB_VERSION}.tar.gz https://github.com/facebook/folly/archive/v${FB_VERSION}.tar.gz
wget -O /tmp/wangle-${FB_VERSION}.tar.gz https://github.com/facebook/wangle/archive/v${FB_VERSION}.tar.gz
wget -O /tmp/fbthrift-${FB_VERSION}.tar.gz https://github.com/facebook/fbthrift/archive/v${FB_VERSION}.tar.gz
wget -O /tmp/proxygen-${FB_VERSION}.tar.gz https://github.com/facebook/proxygen/archive/v${FB_VERSION}.tar.gz
wget -O /tmp/mstch-master.tar.gz https://github.com/no1msd/mstch/archive/master.tar.gz
wget -O /tmp/zstd-${ZSTD_VERSION}.tar.gz https://github.com/facebook/zstd/archive/v${ZSTD_VERSION}.tar.gz
wget -O /tmp/fizz-${FB_VERSION}.tar.gz https://github.com/facebookincubator/fizz/archive/v${FB_VERSION}.tar.gz

tar xzvf folly-${FB_VERSION}.tar.gz
tar xzvf wangle-${FB_VERSION}.tar.gz
tar xzvf fbthrift-${FB_VERSION}.tar.gz
tar xzvf proxygen-${FB_VERSION}.tar.gz
tar xzvf mstch-master.tar.gz
tar xzvf zstd-${ZSTD_VERSION}.tar.gz
tar xzvf fizz-${FB_VERSION}.tar.gz

echo "updating mstch-master..."
pushd mstch-master
cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/facebook-${FB_VERSION} .
make -j $(nproc) install
popd

echo "updating zstd.."
pushd zstd-${ZSTD_VERSION}
make -j $(nproc) install PREFIX=/usr/local/facebook-${FB_VERSION}
popd

echo "updating folly..."
pushd folly-${FB_VERSION}/folly
cd test
rm -rf gtest
wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz
tar zxf release-1.8.0.tar.gz
rm -f release-1.8.0.tar.gz
mv googletest-release-1.8.0 gtest
cd gtest
cmake .
make -j $(nproc) install
cd ../../../
ldconfig
wget https://patch-diff.githubusercontent.com/raw/facebook/folly/pull/866.patch
patch -p1 < 866.patch
mkdir -p build_ && cd build_
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/facebook-${FB_VERSION} -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make -j $(nproc) install
ldconfig
cd ..
popd

echo "updating fizz..."
pushd fizz-${FB_VERSION}/fizz
ldconfig
mkdir -p build_ && cd build_
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/facebook-${FB_VERSION}
make -j $(nproc) install
ldconfig
cd ..
popd

echo "updating wangle..."
pushd wangle-${FB_VERSION}/wangle
ldconfig
mkdir -p build_ && cd build_
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/facebook-${FB_VERSION} -DBUILD_TESTS=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make -j $(nproc)
ctest
make install
ldconfig
cd ..
popd

echo "updating fbthrift..."
pushd fbthrift-${FB_VERSION}/thrift
ldconfig
cd ..
mkdir -p build_ && cd build_
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/facebook-${FB_VERSION}
make -j $(nproc) install
ldconfig
popd


echo "updating proxygen..."
pushd proxygen-${FB_VERSION}/proxygen
# Some extra dependencies for Ubuntu 13.10 and 14.04
sudo apt-get install -yq \
    git \
    cmake \
    g++ \
    flex \
    bison \
    libkrb5-dev \
    libsasl2-dev \
    libnuma-dev \
    pkg-config \
    libssl-dev \
    libcap-dev \
    gperf \
    autoconf-archive \
    libevent-dev \
    libtool \
    libboost-all-dev \
    libjemalloc-dev \
    libsnappy-dev \
    wget \
    unzip \
    libiberty-dev \
    liblz4-dev \
    liblzma-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libsodium-dev
# Build proxygen
autoreconf -ivf
./configure --prefix=/usr/local/facebook-${FB_VERSION}
make -j $(nproc) install
ldconfig
popd