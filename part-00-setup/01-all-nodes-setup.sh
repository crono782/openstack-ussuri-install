#!/bin/bash

# set hostname

# hostnamectl set-hostname <hostname>

# set up networks/ips
# use whatever method you like, but make sure they persist reboot

# copy os-env file to node

source ~/os-env

# set selinux permissive for now, some policies missing breaks a few things

setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/sysconfig/selinux

# stop firewall for now

for i in stop disable;do systemctl $i firewalld;done

# set host entries in lieu of DNS

cat << EOF >> /etc/hosts
$OS_CONTROLLER_IP $OS_CONTROLLER_NM
$OS_COMPUTE_IP $OS_COMPUTE_NM
$OS_NETWORK_IP $OS_NETWORK_NM
$OS_BLOCK_IP $OS_BLOCK_NM
$OS_OBJECT_IP $OS_BLOCK_NM
EOF

# set up NTP

if [ "$(hostname -s)" == "$OS_CONTROLLER_NM" ]; then
  sed -i "s/^#allow.*/allow $OS_MGT_NET\/$OS_MGT_MASK/" /etc/chrony.conf
else
  sed -i -r -e "/^(server 0|pool)/i server $OS_CONTROLLER_NM iburst" -e '/^(server [0-9]|pool)/d' /etc/chrony.conf
fi

systemctl restart chronyd

# create some helper scripts

# backs up conf files and removes comments for a clean slate

cat << EOF > bak.sh
#!/bin/sh
filepath=\$1
cp \$filepath \$filepath.bak
grep '^[^#$]' \$filepath.bak > \$filepath
EOF

chmod +x bak.sh

# helper for adding key/value pairs and sections to conf file

cat << EOF > conf.sh
#!/bin/bash
file=\$1
section=\$2
key=\$3
shift;shift;shift
value="\$@"
if [ "\$(grep -c "^\[\$section\]" \$file)" -lt 1  ]; then
  echo [\$section] >> \$file
fi
if [ ! -z "\$(sed -n "/\[\$section\]/,/\[/{/^\$key =.*/=}" \$file)" ]; then
  sed -i "/\[\$section\]/,/\[/{s/\$key[ =].*/\$key = \$value/}" \$file
else
  sed -i "/^\[\$section\]/a \$key = \$value" \$file
fi
EOF

chmod +x conf.sh

# install base openstack packages
# rpm for release not available yet, set it up manually
mkdir ~/ussuri-release
cd ~/ussuri-release
dnf download centos-release-openstack-train
rpm2cpio centos-release-openstack-train*.rpm|cpio -idmv
mv ~/ussuri-release/etc/yum.repos.d/CentOS-OpenStack-train.repo ~/ussuri-release/etc/yum.repos.d/CentOS-OpenStack-ussuri.repo
sed -i 's/train/ussuri/g' ~/ussuri-release/etc/yum.repos.d/CentOS-OpenStack-ussuri.repo
cp -p ~/ussuri-release/etc/yum.repos.d/* /etc/yum.repos.d/
cp -p ~/ussuri-release/etc/pki/rpm-gpg/* /etc/pki/rpm-gpg/
cd ~
rm -rf ~/ussuri-release
wget -P /etc/pki/rpm-gpg/ https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Cloud
wget -P /etc/pki/rpm-gpg/ https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization-RDO
wget -P /etc/pki/rpm-gpg/ https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Storage

dnf -y upgrade
dnf -y install python3-openstackclient openstack-selinux

exit
