#!/bin/bash

# verifications

source ~/adminrc

openstack volume service list

openstack volume type create HDD
openstack volume type set HDD --property volume_backend_name=lvm-hdd
openstack volume type create SSD
openstack volume type set SSD --property volume_backend_name=lvm-ssd

exit
