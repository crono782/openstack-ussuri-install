#!/bin/bash

# OPTION B: GLANCE FILE BACKEND

source ~/os-env

pip3 install boto3  # maybe this should already be done. threw s3 errors

./conf.sh /etc/glance/glance-api.conf DEFAULT enabled_backends file:file
./conf.sh /etc/glance/glance-api.conf glance_store default_backend file
./conf.sh /etc/glance/glance-api.conf file filesystem_store_datadir /var/lib/glance/images/

exit
