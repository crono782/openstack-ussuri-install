#!/bin/sh

cat << EOF > ~/cinder-volumes-ceph.xml
<secret ephemeral="no" private="no">
  <uuid>$(cat ~/cinder.volumes.uuid.txt)</uuid>
  <usage type="ceph">
    <name>client.volumes secret</name>
  </usage>
</secret>
EOF

cat << EOF > ~/cinder-ecvolumes-ceph.xml
<secret ephemeral="no" private="no">
  <uuid>$(cat ~/cinder.ecvolumes.uuid.txt)</uuid>
  <usage type="ceph">
    <name>client.ecvolumes secret</name>
  </usage>
</secret>
EOF

virsh secret-define --file ~/cinder-volumes-ceph.xml
virsh secret-define --file ~/cinder-ecvolumes-ceph.xml

virsh secret-set-value --secret $(cat ~/cinder.volumes.uuid.txt) --base64 $(cat ~/client.volumes.key)
virsh secret-set-value --secret $(cat ~/cinder.ecvolumes.uuid.txt) --base64 $(cat ~/client.ecvolumes.key)

rm -f ~/{cinder.volumes.uuid.txt,cinder-volumes-ceph.xml,client.volumes.key}
rm -f ~/{cinder.ecvolumes.uuid.txt,cinder-ecvolumes-ceph.xml,client.ecvolumes.key}

exit
