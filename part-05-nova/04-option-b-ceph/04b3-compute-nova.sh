#!/bin/sh

# OPTION B: Ceph backed Nova VM images

dnf -y install epel-release
dnf -y install python3-rbd ceph-common

if [ ! -f /etc/ceph/ceph.conf ]; then
  mv ~/ceph.conf /etc/ceph
fi
mv ~/ceph.client.vms.keyring /etc/ceph

chgrp nova /etc/ceph/ceph.client.vms.keyring
chmod 640 /etc/ceph/ceph.client.vms.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.vms]
keyring = /etc/ceph/ceph.client.vms.keyring
EOF

./conf.sh /etc/nova/nova.conf libvirt images_type rbd
./conf.sh /etc/nova/nova.conf libvirt images_rbd_pool vms
./conf.sh /etc/nova/nova.conf libvirt rbd_secret_uuid $(cat ~/nova.vms.uuid.txt)
./conf.sh /etc/nova/nova.conf libvirt rbd_user vms
./conf.sh /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf

systemctl restart openstack-nova-compute

cat << EOF > ~/nova-vms-ceph.xml
<secret ephemeral="no" private="no">
  <uuid>$(cat ~/nova.vms.uuid.txt)</uuid>
  <usage type="ceph">
    <name>client.vms secret</name>
  </usage>
</secret>
EOF

virsh secret-define --file ~/nova-vms-ceph.xml

virsh secret-set-value --secret $(cat ~/nova.vms.uuid.txt) --base64 $(cat ~/client.vms.key)

rm -f ~/{nova.vms.uuid.txt,nova-vms-ceph.xml,client.vms.key}

exit
