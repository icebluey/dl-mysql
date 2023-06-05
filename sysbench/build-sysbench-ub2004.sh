#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

LDFLAGS='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now'
export LDFLAGS
_ORIG_LDFLAGS="${LDFLAGS}"

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

if ! grep -q -i '^1:.*docker' /proc/1/cgroup; then
    echo
    echo ' Not in a container!'
    echo
    exit 1
fi

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
git clone https://github.com/akopytov/sysbench.git
cd sysbench
rm -fr .git
bash autogen.sh
LDFLAGS='' ; LDFLAGS="${_ORIG_LDFLAGS}"' -Wl,-rpath,/usr/lib/x86_64-linux-gnu/sysbench' ; export LDFLAGS
./configure \
--build=x86_64-linux-gnu --host=x86_64-linux-gnu \
--prefix=/usr \
--with-mysql-includes=/usr/include/mysql \
--with-mysql-libs=/usr/lib/x86_64-linux-gnu/mysql
make
rm -fr /tmp/sysbench
make DESTDIR=/tmp/sysbench install
cd /tmp/sysbench
strip usr/bin/sysbench
install -m 0755 -d usr/lib/x86_64-linux-gnu/sysbench
cp -af "/usr/lib/x86_64-linux-gnu/mysql/$(readelf -d usr/bin/sysbench | grep -i 'Shared library:' | grep -i 'libmysqlclient\.so\.' | sed -e 's|.*\[||g' -e 's|\].*||g')"* usr/lib/x86_64-linux-gnu/sysbench/
chrpath -r '$ORIGIN' usr/lib/x86_64-linux-gnu/sysbench/"$(readelf -d usr/bin/sysbench | grep -i 'Shared library:' | grep -i 'libmysqlclient\.so\.' | sed -e 's|.*\[||g' -e 's|\].*||g')"
cp -af /usr/lib/x86_64-linux-gnu/libstdc++.so.6* usr/lib/x86_64-linux-gnu/sysbench/
cp -af /usr/lib/x86_64-linux-gnu/libgcc_s*.so* usr/lib/x86_64-linux-gnu/sysbench/
rm -fr /tmp/openssl111.tmp
mkdir /tmp/openssl111.tmp
wget -q -O /tmp/openssl111.tmp/.openssl-libs.tar.xz \
"https://github.com/icebluey/openssl-libs/releases/download/v1.1.1u/openssl-libs-1.1.1u-ub.tar.xz"
tar -xof /tmp/openssl111.tmp/.openssl-libs.tar.xz -C /tmp/openssl111.tmp/
cp -af /tmp/openssl111.tmp/openssl*/*.so* usr/lib/x86_64-linux-gnu/sysbench/
sleep 1
rm -fr /tmp/openssl111.tmp
_sysbench_ver="$(./usr/bin/sysbench --version | awk '{print $2}')"
_mysql_ver="$(strings usr/lib/x86_64-linux-gnu/sysbench/$(readelf -d usr/bin/sysbench | grep -i 'Shared library:' | grep -i 'libmysqlclient\.so\.' | sed -e 's|.*\[||g' -e 's|\].*||g') | grep -i '/mysql-8\..*/sql-common/client.cc' | sed 's|/|\n|g' | grep -i '^mysql-' | sed 's|mysql-||g')"
echo
sleep 2
tar -Jcvf /tmp/sysbench-"${_sysbench_ver}"-mysql${_mysql_ver}-1_amd64.tar.xz *
echo
sleep 2
cd /tmp
rm -fr "${_tmp_dir}"
rm -fr /tmp/sysbench
/sbin/ldconfig
echo ' build sysbench done'
exit

