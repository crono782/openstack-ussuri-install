#!/bin/bash

# use tempurl style auth

./endpoint.sh object-store 8080/swift/v1/AUTH_%\(project_id\)s ceph

# swiftclient's info methods don't work for ceph. horizon 18.3.0 introduced a feature that adds policy checks to the ui. since swiftclient couldn't read capabilites, this effectively broke the ui and containers could not be created in it. the following repairs swiftclient to work correctly (i.e. swift capabilities). restart horizon to fix the ui

sed -i '/def get_capabilities(self/,/return/{s|'/info'|/swift/info|}' /usr/lib/python3.6/site-packages/swiftclient/client.py 

systemctl restart httpd memcached

exit
