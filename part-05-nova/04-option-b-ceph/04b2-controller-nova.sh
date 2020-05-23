#!/bin/sh

./conf.sh /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
systemctl restart openstack-glance-api
