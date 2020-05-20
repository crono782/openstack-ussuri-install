#!/bin/sh

# create env file

cat << EOF > ~/ceph-env
OS_CEPH_IP='10.10.10.110'
OS_CEPH_NM='ceph'
OS_CEPH_PUB_NET='10.10.10.0'
OS_CEPH_PUB_MASK='24'
OS_CEPH_FSID=$(uuidgen)
OS_CEPH_CVWEBPORT='7480'
EOF

source ~/ceph-env

# install packages (use cephadm just for adding repos)

dnf -y install python3
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm
chmod +x cephadm
./cephadm add-repo --release octopus
dnf -y install ceph-common ceph-mon ceph-mgr ceph-osd ceph-radosgw

# set firewall rules

firewall-cmd --permanent --add-service=ceph --add-service=ceph-mon
firewall-cmd --permanent --add-port $OS_CEPH_CVWEBPORT/tcp
firewall-cmd --reload

# create ceph.conf

cat << EOF > /etc/ceph/ceph.conf
[global]
fsid = $OS_CEPH_FSID
mon initial members = $OS_CEPH_NM
mon host = $OS_CEPH_IP
public network = ${OS_CEPH_PUB_NET}/${OS_CEPH_PUB_MASK}
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 2
osd pool default pg num = 32
osd pool default pgp num = 32
osd crush chooseleaf type = 0

[client.rgw.$OS_CEPH_NM]
host = $OS_CEPH_NM
rgw dns name = $OS_CEPH_NM
EOF

# create keyrings and bootstrap monitor

ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
chown ceph:ceph /tmp/ceph.mon.keyring
monmaptool --create --add $OS_CEPH_NM $OS_CEPH_IP --fsid $OS_CEPH_FSID /tmp/monmap
mkdir /var/lib/ceph/mon/ceph-${OS_CEPH_NM}
ceph-mon --mkfs -i $OS_CEPH_NM --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

chown -R ceph:ceph /var/lib/ceph/mon
chown -R ceph:ceph /etc/ceph

for i in enable start;do systemctl $i ceph-mon@${OS_CEPH_NM};done
ceph mon enable-msgr2

# create manager 

mkdir /var/lib/ceph/mgr/ceph-${OS_CEPH_NM}
ceph auth get-or-create mgr.`hostname -s` mon 'allow profile mgr' osd 'allow *' mds 'allow *' -o /var/lib/ceph/mgr/ceph-${OS_CEPH_NM}/keyring
chown -R ceph:ceph /var/lib/ceph/mgr
for i in enable start;do systemctl $i ceph-mgr@${OS_CEPH_NM};done

# create OSDs from vdb and vdc disks

for i in b c d;do ceph-volume lvm create --data /dev/vd${i};done

# create rados gw

mkdir -p /var/lib/ceph/radosgw/ceph-rgw.${OS_CEPH_NM}
ceph auth get-or-create client.rgw.${OS_CEPH_NM} osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/ceph-rgw.${OS_CEPH_NM}/keyring
chown -R ceph:ceph /var/lib/ceph/radosgw/

for i in enable start;do systemctl $i ceph-radosgw@rgw.${OS_CEPH_NM};done

# verify stuff

ceph -s

curl http://${OS_CEPH_NM}:${OS_CEPH_CVWEBPORT}

