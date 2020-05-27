#!/bin/bash
# store glance images in swift
# prob doesn't make sense for ceph backend

# conf file work

./conf.sh /etc/glance/glance-api.conf glance_store enabled_backends glance.store.swift.store:swift,file:file
./conf.sh /etc/glance/glance-api.conf glance_store default_backend swift
./conf.sh /etc/glance/glance-api.conf glance.store.swift.store swift_store_create_container_on_put True

exit
