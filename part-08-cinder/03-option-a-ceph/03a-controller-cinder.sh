#!/bin/bash

# verifications

source ~/adminrc

openstack volume service list
openstack volume type list

openstack volume type create Standard-CephRBD --property volume_backend_name=CephRBD --description "Standard Ceph RBD backed storage. Good for general-purpose usage."

openstack volume type create Cold-CephRBD-EC --property volume_backend_name=CephRBD-EC --description "Slower erasure coded Ceph RBD backed storage. Good for data that is infrequently accessed data and slower I/O requirements."

exit
