#!/bin/bash

# verifications

source ~/adminrc

openstack volume service list

openstack volume type create SSD --property volume_backend_name=lvm-ssd --description "SSD-backed storage (simulated) for faster I/O."


openstack volume type create HDD --property volume_backend_name=lvm-hdd --description "HDD-backed storage (simulated) for general-purpose I/O."

exit
