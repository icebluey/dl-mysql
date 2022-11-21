#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

set -e

if [[ -e /bin/rpm2cpio ]]; then
    echo "no file: /bin/rpm2cpio"
    exit 1
fi
if [[ -e /bin/cpio ]]; then
    echo "no file: /bin/cpio"
    exit 1
fi
if [[ -e /usr/bin/printf ]]; then
    echo "no file: /usr/bin/printf"
    exit 1
fi
if [[ -e /bin/dd ]]; then
    echo "no file: /bin/dd"
    exit 1
fi

#_mysql_ver=$(wget -qO- 'https://dev.mysql.com/downloads/mysql/' | grep '<h1>MySQL Community Server 8\.' | sed 's| |\n|g' | grep '^8\.' | sort -V | tail -n 1)

if [[ -z "${1}" ]]; then
    _mysql_ver=$(wget -qO- 'https://dev.mysql.com/downloads/mysql/' | grep '<h1>MySQL Community Server 8\.' | sed 's| |\n|g' | grep '^8\.' | sort -V | tail -n 1)
    echo
    printf '\e[01;32m%s\e[m\n' "MySQL Community Server Latest Version: ${_mysql_ver}"
    echo
else
    _mysql_ver="${1}"
    echo
    printf '\e[01;31m%s\e[m\n' "MySQL Community Server: ${_mysql_ver}"
    echo
fi

sleep 2
rm -fr /tmp/mysql
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-${_mysql_ver}-linux-glibc2.17-x86_64-minimal.tar.xz"
sleep 1
tar -xf "mysql-${_mysql_ver}-linux-glibc2.17-x86_64-minimal.tar.xz"

#wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-Shell/mysql-shell-${_mysql_ver}-linux-glibc2.12-x86-64bit.tar.gz"
#sleep 1
#tar -xf "mysql-shell-${_mysql_ver}-linux-glibc2.12-x86-64bit.tar.gz"

sleep 2
rm -f mysql-*.tar*

###############################################################################
mkdir rpms && cd rpms
#wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-libs-${_mysql_ver}-1.el7.x86_64.rpm"
wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-embedded-compat-${_mysql_ver}-1.el7.x86_64.rpm"
wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-libs-compat-${_mysql_ver}-1.el7.x86_64.rpm"
wget -c -t 0 -T 9 "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-server-${_mysql_ver}-1.el7.x86_64.rpm"
rpm2cpio "mysql-community-embedded-compat-${_mysql_ver}-1.el7.x86_64.rpm" | cpio -mid
rm -f etc/ld.so.conf.d/mysql-x86_64.conf
rpm2cpio "mysql-community-libs-compat-${_mysql_ver}-1.el7.x86_64.rpm" | cpio -mid
rpm2cpio "mysql-community-server-${_mysql_ver}-1.el7.x86_64.rpm" | cpio -mid
sleep 2
rm -fr usr/sbin
rm -f *.rpm
cd ..
###############################################################################

install -m 0755 -d /tmp/mysql/usr/sbin
install -m 0755 -d /tmp/mysql/usr/include
install -m 0755 -d /tmp/mysql/usr/share
install -m 0755 -d /tmp/mysql/usr/lib64
install -m 0755 -d /tmp/mysql/etc/logrotate.d
install -m 0755 -d /tmp/mysql/etc/mysql/conf.d
install -m 0755 -d /tmp/mysql/etc/mysql/mysql.conf.d

sleep 1

cd mysql-*linux-glibc2*x86_64*
cp -fr bin /tmp/mysql/usr/
cp -fr lib /tmp/mysql/usr/lib64/mysql
cp -fr include /tmp/mysql/usr/include/mysql
cp -fr man /tmp/mysql/usr/share/
cp -fr share /tmp/mysql/usr/share/mysql-8.0
cd ..

cd rpms
sed 's|http:|https:|g' -i etc/my.cnf
sed 's|http:|https:|g' -i usr/lib/systemd/system/mysql*service
install -v -c -m 0644 etc/logrotate.d/mysql /tmp/mysql/etc/logrotate.d/
install -v -c -m 0644 etc/my.cnf /tmp/mysql/etc/
install -v -c -m 0644 usr/lib/systemd/system/mysql*service /tmp/mysql/etc/mysql/
install -v -c -m 0644 usr/share/mysql-8.0/mysql-log-rotate /tmp/mysql/usr/share/mysql-8.0/
cp -v -a usr/lib64/mysql/libmysql*so*18* /tmp/mysql/usr/lib64/mysql/

#install -v -c -m 0755 usr/bin/mysqld_pre_systemd /tmp/mysql/usr/bin/
rm -f /tmp/mysql/usr/bin/mysqld_pre_systemd
sleep 1
printf '\x23\x21\x20\x2F\x62\x69\x6E\x2F\x62\x61\x73\x68\x0A\x0A\x23\x20\x43\x6F\x70\x79\x72\x69\x67\x68\x74\x20\x28\x63\x29\x20\x32\x30\x31\x35\x2C\x20\x32\x30\x32\x31\x2C\x20\x4F\x72\x61\x63\x6C\x65\x20\x61\x6E\x64\x2F\x6F\x72\x20\x69\x74\x73\x20\x61\x66\x66\x69\x6C\x69\x61\x74\x65\x73\x2E\x0A\x23\x0A\x23\x20\x54\x68\x69\x73\x20\x70\x72\x6F\x67\x72\x61\x6D\x20\x69\x73\x20\x66\x72\x65\x65\x20\x73\x6F\x66\x74\x77\x61\x72\x65\x3B\x20\x79\x6F\x75\x20\x63\x61\x6E\x20\x72\x65\x64\x69\x73\x74\x72\x69\x62\x75\x74\x65\x20\x69\x74\x20\x61\x6E\x64\x2F\x6F\x72\x20\x6D\x6F\x64\x69\x66\x79\x0A\x23\x20\x69\x74\x20\x75\x6E\x64\x65\x72\x20\x74\x68\x65\x20\x74\x65\x72\x6D\x73\x20\x6F\x66\x20\x74\x68\x65\x20\x47\x4E\x55\x20\x47\x65\x6E\x65\x72\x61\x6C\x20\x50\x75\x62\x6C\x69\x63\x20\x4C\x69\x63\x65\x6E\x73\x65\x2C\x20\x76\x65\x72\x73\x69\x6F\x6E\x20\x32\x2E\x30\x2C\x0A\x23\x20\x61\x73\x20\x70\x75\x62\x6C\x69\x73\x68\x65\x64\x20\x62\x79\x20\x74\x68\x65\x20\x46\x72\x65\x65\x20\x53\x6F\x66\x74\x77\x61\x72\x65\x20\x46\x6F\x75\x6E\x64\x61\x74\x69\x6F\x6E\x2E\x0A\x23\x0A\x23\x20\x54\x68\x69\x73\x20\x70\x72\x6F\x67\x72\x61\x6D\x20\x69\x73\x20\x61\x6C\x73\x6F\x20\x64\x69\x73\x74\x72\x69\x62\x75\x74\x65\x64\x20\x77\x69\x74\x68\x20\x63\x65\x72\x74\x61\x69\x6E\x20\x73\x6F\x66\x74\x77\x61\x72\x65\x20\x28\x69\x6E\x63\x6C\x75\x64\x69\x6E\x67\x0A\x23\x20\x62\x75\x74\x20\x6E\x6F\x74\x20\x6C\x69\x6D\x69\x74\x65\x64\x20\x74\x6F\x20\x4F\x70\x65\x6E\x53\x53\x4C\x29\x20\x74\x68\x61\x74\x20\x69\x73\x20\x6C\x69\x63\x65\x6E\x73\x65\x64\x20\x75\x6E\x64\x65\x72\x20\x73\x65\x70\x61\x72\x61\x74\x65\x20\x74\x65\x72\x6D\x73\x2C\x0A\x23\x20\x61\x73\x20\x64\x65\x73\x69\x67\x6E\x61\x74\x65\x64\x20\x69\x6E\x20\x61\x20\x70\x61\x72\x74\x69\x63\x75\x6C\x61\x72\x20\x66\x69\x6C\x65\x20\x6F\x72\x20\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x20\x6F\x72\x20\x69\x6E\x20\x69\x6E\x63\x6C\x75\x64\x65\x64\x20\x6C\x69\x63\x65\x6E\x73\x65\x0A\x23\x20\x64\x6F\x63\x75\x6D\x65\x6E\x74\x61\x74\x69\x6F\x6E\x2E\x20\x20\x54\x68\x65\x20\x61\x75\x74\x68\x6F\x72\x73\x20\x6F\x66\x20\x4D\x79\x53\x51\x4C\x20\x68\x65\x72\x65\x62\x79\x20\x67\x72\x61\x6E\x74\x20\x79\x6F\x75\x20\x61\x6E\x20\x61\x64\x64\x69\x74\x69\x6F\x6E\x61\x6C\x0A\x23\x20\x70\x65\x72\x6D\x69\x73\x73\x69\x6F\x6E\x20\x74\x6F\x20\x6C\x69\x6E\x6B\x20\x74\x68\x65\x20\x70\x72\x6F\x67\x72\x61\x6D\x20\x61\x6E\x64\x20\x79\x6F\x75\x72\x20\x64\x65\x72\x69\x76\x61\x74\x69\x76\x65\x20\x77\x6F\x72\x6B\x73\x20\x77\x69\x74\x68\x20\x74\x68\x65\x0A\x23\x20\x73\x65\x70\x61\x72\x61\x74\x65\x6C\x79\x20\x6C\x69\x63\x65\x6E\x73\x65\x64\x20\x73\x6F\x66\x74\x77\x61\x72\x65\x20\x74\x68\x61\x74\x20\x74\x68\x65\x79\x20\x68\x61\x76\x65\x20\x69\x6E\x63\x6C\x75\x64\x65\x64\x20\x77\x69\x74\x68\x20\x4D\x79\x53\x51\x4C\x2E\x0A\x23\x0A\x23\x20\x54\x68\x69\x73\x20\x70\x72\x6F\x67\x72\x61\x6D\x20\x69\x73\x20\x64\x69\x73\x74\x72\x69\x62\x75\x74\x65\x64\x20\x69\x6E\x20\x74\x68\x65\x20\x68\x6F\x70\x65\x20\x74\x68\x61\x74\x20\x69\x74\x20\x77\x69\x6C\x6C\x20\x62\x65\x20\x75\x73\x65\x66\x75\x6C\x2C\x0A\x23\x20\x62\x75\x74\x20\x57\x49\x54\x48\x4F\x55\x54\x20\x41\x4E\x59\x20\x57\x41\x52\x52\x41\x4E\x54\x59\x3B\x20\x77\x69\x74\x68\x6F\x75\x74\x20\x65\x76\x65\x6E\x20\x74\x68\x65\x20\x69\x6D\x70\x6C\x69\x65\x64\x20\x77\x61\x72\x72\x61\x6E\x74\x79\x20\x6F\x66\x0A\x23\x20\x4D\x45\x52\x43\x48\x41\x4E\x54\x41\x42\x49\x4C\x49\x54\x59\x20\x6F\x72\x20\x46\x49\x54\x4E\x45\x53\x53\x20\x46\x4F\x52\x20\x41\x20\x50\x41\x52\x54\x49\x43\x55\x4C\x41\x52\x20\x50\x55\x52\x50\x4F\x53\x45\x2E\x20\x20\x53\x65\x65\x20\x74\x68\x65\x0A\x23\x20\x47\x4E\x55\x20\x47\x65\x6E\x65\x72\x61\x6C\x20\x50\x75\x62\x6C\x69\x63\x20\x4C\x69\x63\x65\x6E\x73\x65\x2C\x20\x76\x65\x72\x73\x69\x6F\x6E\x20\x32\x2E\x30\x2C\x20\x66\x6F\x72\x20\x6D\x6F\x72\x65\x20\x64\x65\x74\x61\x69\x6C\x73\x2E\x0A\x23\x0A\x23\x20\x59\x6F\x75\x20\x73\x68\x6F\x75\x6C\x64\x20\x68\x61\x76\x65\x20\x72\x65\x63\x65\x69\x76\x65\x64\x20\x61\x20\x63\x6F\x70\x79\x20\x6F\x66\x20\x74\x68\x65\x20\x47\x4E\x55\x20\x47\x65\x6E\x65\x72\x61\x6C\x20\x50\x75\x62\x6C\x69\x63\x20\x4C\x69\x63\x65\x6E\x73\x65\x0A\x23\x20\x61\x6C\x6F\x6E\x67\x20\x77\x69\x74\x68\x20\x74\x68\x69\x73\x20\x70\x72\x6F\x67\x72\x61\x6D\x3B\x20\x69\x66\x20\x6E\x6F\x74\x2C\x20\x77\x72\x69\x74\x65\x20\x74\x6F\x20\x74\x68\x65\x20\x46\x72\x65\x65\x20\x53\x6F\x66\x74\x77\x61\x72\x65\x0A\x23\x20\x46\x6F\x75\x6E\x64\x61\x74\x69\x6F\x6E\x2C\x20\x49\x6E\x63\x2E\x2C\x20\x35\x31\x20\x46\x72\x61\x6E\x6B\x6C\x69\x6E\x20\x53\x74\x2C\x20\x46\x69\x66\x74\x68\x20\x46\x6C\x6F\x6F\x72\x2C\x20\x42\x6F\x73\x74\x6F\x6E\x2C\x20\x4D\x41\x20\x30\x32\x31\x31\x30\x2D\x31\x33\x30\x31\x20\x20\x55\x53\x41\x0A\x0A\x0A\x23\x20\x53\x63\x72\x69\x70\x74\x20\x75\x73\x65\x64\x20\x62\x79\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x6D\x79\x73\x71\x6C\x64\x2E\x73\x65\x72\x76\x69\x63\x65\x20\x74\x6F\x20\x72\x75\x6E\x20\x62\x65\x66\x6F\x72\x65\x20\x65\x78\x65\x63\x75\x74\x69\x6E\x67\x20\x6D\x79\x73\x71\x6C\x64\x0A\x0A\x67\x65\x74\x5F\x6F\x70\x74\x69\x6F\x6E\x20\x28\x29\x20\x7B\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x73\x65\x63\x74\x69\x6F\x6E\x3D\x24\x31\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x6F\x70\x74\x69\x6F\x6E\x3D\x24\x32\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x64\x65\x66\x61\x75\x6C\x74\x3D\x24\x33\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x69\x6E\x73\x74\x61\x6E\x63\x65\x3D\x24\x34\x0A\x20\x20\x20\x20\x72\x65\x74\x3D\x24\x28\x2F\x75\x73\x72\x2F\x62\x69\x6E\x2F\x6D\x79\x5F\x70\x72\x69\x6E\x74\x5F\x64\x65\x66\x61\x75\x6C\x74\x73\x20\x20\x24\x7B\x69\x6E\x73\x74\x61\x6E\x63\x65\x3A\x2B\x2D\x2D\x64\x65\x66\x61\x75\x6C\x74\x73\x2D\x67\x72\x6F\x75\x70\x2D\x73\x75\x66\x66\x69\x78\x3D\x40\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x7D\x20\x24\x73\x65\x63\x74\x69\x6F\x6E\x20\x7C\x20\x5C\x0A\x09\x20\x20\x20\x20\x20\x20\x67\x72\x65\x70\x20\x27\x5E\x2D\x2D\x27\x24\x7B\x6F\x70\x74\x69\x6F\x6E\x7D\x27\x3D\x27\x20\x7C\x20\x63\x75\x74\x20\x2D\x64\x3D\x20\x2D\x66\x32\x2D\x20\x7C\x20\x74\x61\x69\x6C\x20\x2D\x6E\x20\x31\x29\x0A\x20\x20\x20\x20\x5B\x20\x2D\x7A\x20\x22\x24\x72\x65\x74\x22\x20\x5D\x20\x26\x26\x20\x72\x65\x74\x3D\x24\x64\x65\x66\x61\x75\x6C\x74\x0A\x20\x20\x20\x20\x65\x63\x68\x6F\x20\x24\x72\x65\x74\x0A\x7D\x0A\x0A\x69\x6E\x73\x74\x61\x6C\x6C\x5F\x76\x61\x6C\x69\x64\x61\x74\x65\x5F\x70\x61\x73\x73\x77\x6F\x72\x64\x5F\x73\x71\x6C\x5F\x66\x69\x6C\x65\x20\x28\x29\x20\x7B\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x69\x6E\x69\x74\x66\x69\x6C\x65\x0A\x20\x20\x20\x20\x69\x6E\x69\x74\x66\x69\x6C\x65\x3D\x22\x24\x28\x6D\x6B\x74\x65\x6D\x70\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x66\x69\x6C\x65\x73\x2F\x69\x6E\x73\x74\x61\x6C\x6C\x2D\x76\x61\x6C\x69\x64\x61\x74\x65\x2D\x70\x61\x73\x73\x77\x6F\x72\x64\x2D\x70\x6C\x75\x67\x69\x6E\x2E\x58\x58\x58\x58\x58\x58\x2E\x73\x71\x6C\x29\x22\x0A\x20\x20\x20\x20\x63\x68\x6D\x6F\x64\x20\x61\x2B\x72\x20\x22\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x22\x0A\x20\x20\x20\x20\x65\x63\x68\x6F\x20\x22\x53\x45\x54\x20\x40\x40\x53\x45\x53\x53\x49\x4F\x4E\x2E\x53\x51\x4C\x5F\x4C\x4F\x47\x5F\x42\x49\x4E\x3D\x30\x3B\x22\x20\x3E\x20\x22\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x22\x0A\x20\x20\x20\x20\x65\x63\x68\x6F\x20\x22\x49\x4E\x53\x45\x52\x54\x20\x49\x4E\x54\x4F\x20\x6D\x79\x73\x71\x6C\x2E\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x20\x28\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x5F\x69\x64\x2C\x20\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x5F\x67\x72\x6F\x75\x70\x5F\x69\x64\x2C\x20\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x5F\x75\x72\x6E\x29\x20\x56\x41\x4C\x55\x45\x53\x20\x28\x31\x2C\x20\x31\x2C\x20\x27\x66\x69\x6C\x65\x3A\x2F\x2F\x63\x6F\x6D\x70\x6F\x6E\x65\x6E\x74\x5F\x76\x61\x6C\x69\x64\x61\x74\x65\x5F\x70\x61\x73\x73\x77\x6F\x72\x64\x27\x29\x3B\x22\x20\x3E\x3E\x20\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x0A\x20\x20\x20\x20\x65\x63\x68\x6F\x20\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x0A\x7D\x0A\x0A\x66\x69\x78\x5F\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x20\x28\x29\x20\x7B\x0A\x20\x20\x20\x20\x64\x61\x74\x61\x64\x69\x72\x3D\x24\x28\x67\x65\x74\x5F\x6F\x70\x74\x69\x6F\x6E\x20\x6D\x79\x73\x71\x6C\x64\x20\x64\x61\x74\x61\x64\x69\x72\x20\x22\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x24\x7B\x69\x6E\x73\x74\x61\x6E\x63\x65\x3A\x2B\x2D\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x7D\x22\x20\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x29\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x2D\x64\x20\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x5D\x20\x20\x26\x26\x20\x5B\x20\x2D\x4F\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x2F\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x22\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x09\x63\x68\x6F\x77\x6E\x20\x2D\x2D\x72\x65\x66\x65\x72\x65\x6E\x63\x65\x3D\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x2F\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x22\x0A\x09\x69\x66\x20\x5B\x20\x2D\x78\x20\x2F\x75\x73\x72\x2F\x62\x69\x6E\x2F\x63\x68\x63\x6F\x6E\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x62\x69\x6E\x2F\x63\x68\x63\x6F\x6E\x20\x2D\x2D\x72\x65\x66\x65\x72\x65\x6E\x63\x65\x3D\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x2F\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x22\x20\x3E\x20\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x32\x3E\x26\x31\x0A\x09\x66\x69\x0A\x20\x20\x20\x20\x66\x69\x0A\x7D\x0A\x0A\x69\x6E\x73\x74\x61\x6C\x6C\x5F\x64\x62\x20\x28\x29\x20\x7B\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x64\x20\x2F\x76\x61\x72\x2F\x72\x75\x6E\x2F\x6D\x79\x73\x71\x6C\x64\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2D\x64\x20\x2D\x6D\x20\x30\x37\x35\x35\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x2F\x76\x61\x72\x2F\x72\x75\x6E\x2F\x6D\x79\x73\x71\x6C\x64\x20\x7C\x7C\x20\x65\x78\x69\x74\x20\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x64\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x66\x69\x6C\x65\x73\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2D\x64\x20\x2D\x6D\x20\x30\x37\x35\x30\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x66\x69\x6C\x65\x73\x20\x7C\x7C\x20\x65\x78\x69\x74\x20\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x64\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x6B\x65\x79\x72\x69\x6E\x67\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2D\x64\x20\x2D\x6D\x20\x30\x37\x35\x30\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x6B\x65\x79\x72\x69\x6E\x67\x20\x7C\x7C\x20\x65\x78\x69\x74\x20\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x64\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2D\x64\x20\x2D\x6D\x20\x30\x37\x35\x31\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x20\x7C\x7C\x20\x65\x78\x69\x74\x20\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x0A\x20\x20\x20\x20\x23\x20\x4E\x6F\x74\x65\x3A\x20\x73\x6F\x6D\x65\x74\x68\x69\x6E\x67\x20\x64\x69\x66\x66\x65\x72\x65\x6E\x74\x20\x74\x68\x61\x6E\x20\x64\x61\x74\x61\x64\x69\x72\x3D\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x20\x72\x65\x71\x75\x69\x72\x65\x73\x20\x53\x45\x4C\x69\x6E\x75\x78\x20\x70\x6F\x6C\x69\x63\x79\x20\x63\x68\x61\x6E\x67\x65\x73\x20\x28\x69\x6E\x20\x65\x6E\x66\x6F\x72\x63\x69\x6E\x67\x20\x6D\x6F\x64\x65\x29\x0A\x0A\x20\x20\x20\x20\x23\x20\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x20\x66\x69\x6C\x65\x20\x73\x68\x6F\x75\x6C\x64\x20\x62\x65\x20\x6F\x77\x6E\x65\x64\x20\x62\x79\x20\x6D\x79\x73\x71\x6C\x20\x75\x73\x65\x72\x20\x73\x69\x6E\x63\x65\x20\x4D\x79\x53\x51\x4C\x20\x38\x2E\x30\x2E\x31\x36\x0A\x20\x20\x20\x20\x66\x69\x78\x5F\x6D\x79\x73\x71\x6C\x5F\x75\x70\x67\x72\x61\x64\x65\x5F\x69\x6E\x66\x6F\x0A\x0A\x20\x20\x20\x20\x23\x20\x4E\x6F\x20\x61\x75\x74\x6F\x6D\x61\x74\x69\x63\x20\x69\x6E\x69\x74\x20\x77\x61\x6E\x74\x65\x64\x0A\x20\x20\x20\x20\x5B\x20\x2D\x65\x20\x2F\x65\x74\x63\x2F\x73\x79\x73\x63\x6F\x6E\x66\x69\x67\x2F\x6D\x79\x73\x71\x6C\x20\x5D\x20\x26\x26\x20\x2E\x20\x2F\x65\x74\x63\x2F\x73\x79\x73\x63\x6F\x6E\x66\x69\x67\x2F\x6D\x79\x73\x71\x6C\x0A\x20\x20\x20\x20\x5B\x20\x2D\x6E\x20\x22\x24\x4E\x4F\x5F\x49\x4E\x49\x54\x22\x20\x5D\x20\x26\x26\x20\x65\x78\x69\x74\x20\x30\x0A\x0A\x20\x20\x20\x20\x6C\x6F\x63\x61\x6C\x20\x69\x6E\x73\x74\x61\x6E\x63\x65\x3D\x24\x31\x0A\x20\x20\x20\x20\x64\x61\x74\x61\x64\x69\x72\x3D\x24\x28\x67\x65\x74\x5F\x6F\x70\x74\x69\x6F\x6E\x20\x6D\x79\x73\x71\x6C\x64\x20\x64\x61\x74\x61\x64\x69\x72\x20\x22\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x24\x7B\x69\x6E\x73\x74\x61\x6E\x63\x65\x3A\x2B\x2D\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x7D\x22\x20\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x29\x0A\x20\x20\x20\x20\x6C\x6F\x67\x3D\x24\x28\x67\x65\x74\x5F\x6F\x70\x74\x69\x6F\x6E\x20\x6D\x79\x73\x71\x6C\x64\x20\x27\x6C\x6F\x67\x5B\x5F\x2D\x5D\x65\x72\x72\x6F\x72\x27\x20\x22\x2F\x76\x61\x72\x2F\x6C\x6F\x67\x2F\x6D\x79\x73\x71\x6C\x24\x7B\x69\x6E\x73\x74\x61\x6E\x63\x65\x3A\x2B\x2D\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x7D\x2E\x6C\x6F\x67\x22\x20\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x29\x0A\x0A\x20\x20\x20\x20\x23\x20\x52\x65\x73\x74\x6F\x72\x65\x20\x6C\x6F\x67\x2C\x20\x64\x69\x72\x2C\x20\x70\x65\x72\x6D\x73\x20\x61\x6E\x64\x20\x53\x45\x4C\x69\x6E\x75\x78\x20\x63\x6F\x6E\x74\x65\x78\x74\x73\x0A\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x64\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x2D\x61\x20\x21\x20\x2D\x68\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x2D\x61\x20\x22\x78\x24\x28\x64\x69\x72\x6E\x61\x6D\x65\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x29\x22\x20\x3D\x20\x22\x78\x2F\x76\x61\x72\x2F\x6C\x69\x62\x22\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x09\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2D\x64\x20\x2D\x6D\x20\x30\x37\x35\x31\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x7C\x7C\x20\x65\x78\x69\x74\x20\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x21\x20\x2D\x65\x20\x22\x24\x6C\x6F\x67\x22\x20\x2D\x61\x20\x21\x20\x2D\x68\x20\x22\x24\x6C\x6F\x67\x22\x20\x2D\x61\x20\x78\x24\x28\x64\x69\x72\x6E\x61\x6D\x65\x20\x22\x24\x6C\x6F\x67\x22\x29\x20\x3D\x20\x22\x78\x2F\x76\x61\x72\x2F\x6C\x6F\x67\x22\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x09\x63\x61\x73\x65\x20\x24\x28\x62\x61\x73\x65\x6E\x61\x6D\x65\x20\x22\x24\x6C\x6F\x67\x22\x29\x20\x69\x6E\x0A\x09\x20\x20\x20\x20\x6D\x79\x73\x71\x6C\x2A\x2E\x6C\x6F\x67\x29\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x2D\x6D\x30\x36\x34\x30\x20\x2D\x6F\x6D\x79\x73\x71\x6C\x20\x2D\x67\x6D\x79\x73\x71\x6C\x20\x22\x24\x6C\x6F\x67\x22\x20\x3B\x3B\x0A\x09\x20\x20\x20\x20\x2A\x29\x20\x3B\x3B\x0A\x09\x65\x73\x61\x63\x0A\x20\x20\x20\x20\x66\x69\x0A\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x2D\x78\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x72\x65\x73\x74\x6F\x72\x65\x63\x6F\x6E\x20\x5D\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x72\x65\x73\x74\x6F\x72\x65\x63\x6F\x6E\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x5B\x20\x2D\x65\x20\x22\x24\x6C\x6F\x67\x22\x20\x5D\x20\x26\x26\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x72\x65\x73\x74\x6F\x72\x65\x63\x6F\x6E\x20\x22\x24\x6C\x6F\x67\x22\x0A\x09\x66\x6F\x72\x20\x64\x69\x72\x20\x69\x6E\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x66\x69\x6C\x65\x73\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x2D\x6B\x65\x79\x72\x69\x6E\x67\x20\x3B\x20\x64\x6F\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x2D\x78\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x73\x65\x6D\x61\x6E\x61\x67\x65\x20\x2D\x61\x20\x2D\x64\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x20\x2D\x61\x20\x2D\x64\x20\x24\x64\x69\x72\x20\x5D\x20\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x73\x65\x6D\x61\x6E\x61\x67\x65\x20\x66\x63\x6F\x6E\x74\x65\x78\x74\x20\x2D\x61\x20\x2D\x65\x20\x2F\x76\x61\x72\x2F\x6C\x69\x62\x2F\x6D\x79\x73\x71\x6C\x20\x24\x64\x69\x72\x20\x3E\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x32\x3E\x26\x31\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x73\x62\x69\x6E\x2F\x72\x65\x73\x74\x6F\x72\x65\x63\x6F\x6E\x20\x2D\x72\x20\x24\x64\x69\x72\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x66\x69\x0A\x09\x64\x6F\x6E\x65\x0A\x20\x20\x20\x20\x66\x69\x0A\x0A\x20\x20\x20\x20\x23\x20\x49\x66\x20\x73\x70\x65\x63\x69\x61\x6C\x20\x6D\x79\x73\x71\x6C\x20\x64\x69\x72\x20\x69\x73\x20\x69\x6E\x20\x70\x6C\x61\x63\x65\x2C\x20\x73\x6B\x69\x70\x20\x64\x62\x20\x69\x6E\x73\x74\x61\x6C\x6C\x0A\x20\x20\x20\x20\x5B\x20\x2D\x64\x20\x22\x24\x64\x61\x74\x61\x64\x69\x72\x2F\x6D\x79\x73\x71\x6C\x22\x20\x5D\x20\x26\x26\x20\x65\x78\x69\x74\x20\x30\x0A\x0A\x20\x20\x20\x20\x23\x20\x43\x72\x65\x61\x74\x65\x20\x69\x6E\x69\x74\x69\x61\x6C\x20\x64\x62\x20\x61\x6E\x64\x20\x69\x6E\x73\x74\x61\x6C\x6C\x20\x76\x61\x6C\x69\x64\x61\x74\x65\x5F\x70\x61\x73\x73\x77\x6F\x72\x64\x20\x70\x6C\x75\x67\x69\x6E\x0A\x20\x20\x20\x20\x69\x6E\x69\x74\x66\x69\x6C\x65\x3D\x22\x24\x28\x69\x6E\x73\x74\x61\x6C\x6C\x5F\x76\x61\x6C\x69\x64\x61\x74\x65\x5F\x70\x61\x73\x73\x77\x6F\x72\x64\x5F\x73\x71\x6C\x5F\x66\x69\x6C\x65\x29\x22\x0A\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x6D\x79\x73\x71\x6C\x64\x20\x24\x7B\x69\x6E\x73\x74\x61\x6E\x63\x65\x3A\x2B\x2D\x2D\x64\x65\x66\x61\x75\x6C\x74\x73\x2D\x67\x72\x6F\x75\x70\x2D\x73\x75\x66\x66\x69\x78\x3D\x40\x24\x69\x6E\x73\x74\x61\x6E\x63\x65\x7D\x20\x2D\x2D\x69\x6E\x69\x74\x69\x61\x6C\x69\x7A\x65\x20\x5C\x0A\x09\x09\x20\x20\x20\x20\x20\x2D\x2D\x64\x61\x74\x61\x64\x69\x72\x3D\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x2D\x2D\x75\x73\x65\x72\x3D\x6D\x79\x73\x71\x6C\x20\x2D\x2D\x69\x6E\x69\x74\x2D\x66\x69\x6C\x65\x3D\x22\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x22\x0A\x20\x20\x20\x20\x72\x6D\x20\x2D\x66\x20\x22\x24\x69\x6E\x69\x74\x66\x69\x6C\x65\x22\x0A\x0A\x20\x20\x20\x20\x23\x20\x47\x65\x6E\x65\x72\x61\x74\x65\x20\x63\x65\x72\x74\x73\x20\x69\x66\x20\x6E\x65\x65\x64\x65\x64\x0A\x20\x20\x20\x20\x69\x66\x20\x5B\x20\x2D\x78\x20\x2F\x75\x73\x72\x2F\x62\x69\x6E\x2F\x6D\x79\x73\x71\x6C\x5F\x73\x73\x6C\x5F\x72\x73\x61\x5F\x73\x65\x74\x75\x70\x20\x2D\x61\x20\x21\x20\x2D\x65\x20\x22\x24\x7B\x64\x61\x74\x61\x64\x69\x72\x7D\x2F\x73\x65\x72\x76\x65\x72\x2D\x6B\x65\x79\x2E\x70\x65\x6D\x22\x20\x5D\x20\x3B\x20\x74\x68\x65\x6E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x62\x69\x6E\x2F\x6D\x79\x73\x71\x6C\x5F\x73\x73\x6C\x5F\x72\x73\x61\x5F\x73\x65\x74\x75\x70\x20\x2D\x2D\x64\x61\x74\x61\x64\x69\x72\x3D\x22\x24\x64\x61\x74\x61\x64\x69\x72\x22\x20\x2D\x2D\x75\x69\x64\x3D\x6D\x79\x73\x71\x6C\x20\x3E\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x32\x3E\x26\x31\x0A\x20\x20\x20\x20\x66\x69\x0A\x20\x20\x20\x20\x65\x78\x69\x74\x20\x30\x0A\x7D\x0A\x0A\x69\x6E\x73\x74\x61\x6C\x6C\x5F\x64\x62\x20\x24\x31\x0A\x0A\x65\x78\x69\x74\x20\x30\x0A' | dd seek=$((0x0)) conv=notrunc bs=1 of=/tmp/mysql/usr/bin/mysqld_pre_systemd
sleep 1
chmod 0755 /tmp/mysql/usr/bin/mysqld_pre_systemd

cd ..

# mysql-shell
#cd mysql-shell-${_mysql_ver}-*
#find lib/ -type f -iname '*.so*' -exec chmod 0755 '{}' \;
#sleep 2
#find lib/ -type f -iname '*.so*' -exec strip '{}' \;
#install -c -m 0755 bin/* /tmp/mysql/usr/bin/
#sleep 2
#mv -f lib /tmp/mysql/usr/
#mv -f share/mysqlsh /tmp/mysql/usr/share/
#cd ..

mv -f /tmp/mysql/usr/share/mysql-8.0/aclocal /tmp/mysql/usr/share/
mv -f /tmp/mysql/usr/bin/mysqld /tmp/mysql/usr/sbin/
mv -f /tmp/mysql/usr/lib64/mysql/pkgconfig /tmp/mysql/usr/lib64/

sed 's|^prefix=.*|prefix=/usr|g' -i /tmp/mysql/usr/lib64/pkgconfig/mysql*.pc
sed '/^libdir/s|libdir=${prefix}/lib.*|libdir=${prefix}/lib64/mysql|g' -i /tmp/mysql/usr/lib64/pkgconfig/mysql*.pc

cd /tmp/mysql
###############################################################################

find -L usr/share/man/ -type l -exec rm -f '{}' \;
find usr/share/man/ -type f -exec gzip -f -9 '{}' \;
sleep 2
find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
sleep 2
find -L usr/share/man/ -type l -exec rm -f '{}' \;

find usr/bin/ -type f -exec file '{}' \; | \
  sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

find usr/sbin/ -type f -exec file '{}' \; | \
  sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

find usr/lib64/mysql/ -type f -iname '*.so*' -exec file '{}' \; | \
  sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

echo '
cd "$(dirname "$0")"
rm -f /lib/systemd/system/mysql.service
rm -f /lib/systemd/system/'\''mysql@.service'\''
rm -f /lib/systemd/system/mysqld.service
rm -f /lib/systemd/system/'\''mysqld@.service'\''
sleep 1
systemctl daemon-reload >/dev/null 2>&1 || :
install -v -c -m 0644 mysqld.service /lib/systemd/system/
install -v -c -m 0644 '\''mysqld@.service'\'' /lib/systemd/system/

echo '\''/usr/lib64/mysql'\'' > /etc/ld.so.conf.d/mysql-x86_64.conf

userdel -f -r mysql >/dev/null 2>&1 || : 
groupdel -f mysql >/dev/null 2>&1 || : 
sleep 1

getent group mysql >/dev/null || groupadd -r mysql
getent passwd mysql >/dev/null || /usr/sbin/useradd -M -N -g mysql -r \
    -d /var/lib/mysql -s /usr/sbin/nologin -c "MySQL Server" mysql
sleep 1

[ -e /var/log/mysqld.log ] || install -m 0640 -o mysql -g mysql \
    /dev/null /var/log/mysqld.log >/dev/null 2>&1 || : 
install -m 0751 -d -o mysql -g mysql /var/lib/mysql
install -m 0750 -d -o mysql -g mysql /var/lib/mysql-files
install -m 0750 -d -o mysql -g mysql /var/lib/mysql-keyring
install -m 0755 -d -o mysql -g mysql /var/run/mysqld

if [[ -e /usr/lib64/mysql/private && ! -e /usr/lib/private ]]; then
    ln -vs ../lib64/mysql/private /usr/lib/private
else
    echo
    /bin/ls --color -lah /usr/lib/private
    echo
fi

#if [[ -e /usr/lib64/mysql/plugin && ! -e /usr/lib/plugin ]]; then
#    ln -vs ../lib64/mysql/plugin /usr/lib/plugin
#fi

sleep 1
systemctl daemon-reload >/dev/null 2>&1 || :
/sbin/ldconfig
' > etc/mysql/.install.txt

###############################################################################

mv -f -v etc/my.cnf etc/mysql/mysql.conf.d/mysqld.cnf

echo '!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
' > etc/my.cnf

# [mysql]
echo '[mysql]
plugin_dir    = /usr/lib64/mysql/plugin/
socket        = /var/run/mysqld/mysqld.sock
character_sets_dir = /usr/share/mysql-8.0/charsets/
tls_version = TLSv1.3,TLSv1.2
ssl_mode = PREFERRED
#ssl_mode = REQUIRED
' > etc/mysql/conf.d/mysql.cnf

# [mysqld]
echo '[mysqld]
# Remove the leading "# " to disable binary logging
# Binary logging captures changes between backups and is enabled by
# default. It'\''s default setting is log_bin=binlog
# disable_log_bin
#
# Remove leading # to revert to previous value for default_authentication_plugin,
# this will increase compatibility with older clients. For background, see:
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin
# default-authentication-plugin=mysql_native_password

default-time-zone = "+00:00"
# All SQL modes
#sql_mode = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
# Customized SQL modes
sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
autocommit = OFF

log-error     = /var/log/mysqld.log
plugin_dir    = /usr/lib64/mysql/plugin/

pid-file      = /var/run/mysqld/mysqld.pid
datadir       = /var/lib/mysql
tmpdir        = /tmp
socket        = /var/run/mysqld/mysqld.sock
mysqlx_socket = /var/run/mysqld/mysqlx.sock
lc-messages-dir = /usr/share/mysql-8.0
lc-messages = en_US
character_sets_dir = /usr/share/mysql-8.0/charsets/

admin_tls_version = TLSv1.3,TLSv1.2
tls_version = TLSv1.3,TLSv1.2
admin_tls_ciphersuites = TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384
tls_ciphersuites = TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384
admin_ssl_cipher = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
ssl_cipher = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384

binlog_format = ROW
# 最小4096,默认32768
binlog_cache_size = 1MB
log_bin = binlog
# server_id = 100
# 最小1,最大1000000,默认25000
binlog_transaction_dependency_history_size = 25000
# 可能的值COMMIT_ORDER, WRITESET, WRITESET_SESSION
binlog_transaction_dependency_tracking = WRITESET
#slave_parallel_type = LOGICAL_CLOCK
#slave_parallel_workers = 128
#slave_preserve_commit_order = ON
replica_parallel_type = LOGICAL_CLOCK
replica_parallel_workers = 128
replica_preserve_commit_order = ON

# file 
# 设置每个表一个文件
innodb_file_per_table = ON
# 设置logfile大小,最小4MB,默认48MB
# (innodb_log_file_size * innodb_log_files_in_group) 不能超过512GB
innodb_log_file_size = 2GB
# 设置logfile组个数,最小2,最大100,默认2
innodb_log_files_in_group = 2
# 设置最大打开表个数,最小10,最大2147483647
innodb_open_files = 8192
# 在线收缩undo log使用的空间
innodb_undo_log_truncate = ON
innodb_max_undo_log_size = 1GB

# buffers
# 设置buffer pool size,一般为服务器内存60%-80%
# 自动调整到等于或者整数倍于 (innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances)
innodb_buffer_pool_size = 2GB
# 默认128MB
innodb_buffer_pool_chunk_size = 128MB
# 设置buffer pool instance个数,最小1,最大64,提高并发能力
innodb_buffer_pool_instances = 2
# 设置log buffer size大小,最小1MB,最大4095MB,默认16MB
innodb_log_buffer_size = 64MB

# tune
# 设置每次sync_binlog事务提交刷盘,最小0,默认1
#   为了保证binlog的安全,MySQL引入sync_binlog参数来控制binlog刷新到磁盘的频率
#   1 表示事务提交之前,MySQL都需要先把binlog刷新到磁盘.
#   这样的话,即使出现数据库主机操作系统崩溃或者主机突然掉电的情况,
#   系统最多损失prepared状态的事务.设置sync_binlog=1,尽可能保证数据安全.
#   0 表示MySQL不控制binlog的刷新,由文件系统自己控制文件缓存的刷新.
#   N,如果N不等于0或者1,刷新方式同sync_binlog=1类似,只不过此时会延长刷新频率至N次binlog提交组被收集之后
sync_binlog = 1
# 每次事务提交时MySQL都会把log buffer的数据写入log file,并且flush(刷到磁盘)中去
#   可能值0,1,2,默认1
#   0 log buffer 将每秒一次地写入 log file 中,并且 log file 的 flush (刷到磁盘) 操作同时进行.
#     该模式下,在事务提交的时候,不会主动触发写入磁盘的操作.
#   2 每次事务提交时MySQL都会把log buffer的数据写入log file. 但是flush (刷到磁盘) 操作并不会同时进行.
#     该模式下,MySQL会每秒执行一次flush (刷到磁盘) 操作.
#   1 每次事务提交时MySQL都会把log buffer的数据写入log file,并且flush (刷到磁盘) 中去.
innodb_flush_log_at_trx_commit = 1
# 开启异步IO, ON/OFF
innodb_use_native_aio = ON
# 设置innodb数据文件及redo log的打开,刷写模式
# 可能的值fsync, O_DSYNC, littlesync, nosync, O_DIRECT, O_DIRECT_NO_FSYNC
# unix默认fsync
# O_DIRECT : 数据文件IO走direct_io模式，redo日志文件走系统缓存（linux page cache）模式，在IO完成后均使用fsync()进行持久化
# O_DIRECT_NO_FSYNC : 使用O_DIRECT完成IO后，不调用fsync()刷盘. MySQL 8.0.14之前,不适用于XFS and EXT4
innodb_flush_method = O_DIRECT_NO_FSYNC
# 设置innodb 后台线程每秒最大iops上限,最小100,默认200,最大2**64-1
# 通过测试工具获得磁盘io性能后,设置为iops数值/2
innodb_io_capacity = 2000
# 设置压力下innodb 后台线程每秒最大iops上限,最小100,最大2**64-1
# 用iometer测试后的iops数值就好
innodb_io_capacity_max = 4000
# 设置page cleaner线程每次刷脏页的数量,最小100,最大2**64-1,默认1024
innodb_lru_scan_depth = 9000
# 设置将脏数据写入到磁盘的线程数,建议与innodb_buffer_pool_instances相等
innodb_page_cleaners = 2
' > etc/mysql/mysql.conf.d/mysqld.cnf

sleep 1
if [[ ${_mysql_ver} > 8.0.29 ]]; then
    sed 's|^innodb_log_file_size =|#innodb_log_file_size =|g' -i etc/mysql/mysql.conf.d/mysqld.cnf
    sed 's|^innodb_log_files_in_group =|#innodb_log_files_in_group =|g' -i etc/mysql/mysql.conf.d/mysqld.cnf
    sed '/^innodb_file_per_table =/ainnodb_redo_log_capacity = 4GB' -i etc/mysql/mysql.conf.d/mysqld.cnf
fi

###############################################################################

chmod 0644 etc/mysql/conf.d/mysql.cnf
chmod 0644 etc/mysql/mysql.conf.d/mysqld.cnf
chown -R root:root /tmp/mysql

echo
sleep 2
tar -Jcvf /tmp/"mysql-${_mysql_ver}-1.el7.x86_64.tar.xz" *
echo
sleep 2
cd /tmp
sha256sum "mysql-${_mysql_ver}-1.el7.x86_64.tar.xz" > "mysql-${_mysql_ver}-1.el7.x86_64.tar.xz".sha256

cd /tmp
sleep 2
rm -fr "${_tmp_dir}"
rm -fr /tmp/mysql
echo
printf '\e[01;32m%s\e[m\n' '  done'
echo
exit

