#!/bin/bash

# install packages

dnf -y --enablerepo=PowerTools install openstack-dashboard

# config work

cp -p /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.bkp
cp -p /usr/share/openstack-dashboard/openstack_dashboard/defaults.py /usr/share/openstack-dashboard/openstack_dashboard/defaults.py.bkp


sed -i 's/^OPENSTACK_HOST.*/OPENSTACK_HOST = "controller"/' /etc/openstack-dashboard/local_settings
sed -i "s/^ALLOWED_HOSTS.*/ALLOWED_HOSTS = ['*']/" /etc/openstack-dashboard/local_settings
sed -i '/^#CACHES/,/\}$/{s/^#//;s/127.0.0.1/controller/}' /etc/openstack-dashboard/local_settings
sed -i "s/#\+SESSION_ENGINE.*/SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/" /etc/openstack-dashboard/local_settings 
sed -i 's/^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "member"/' /usr/share/openstack-dashboard/openstack_dashboard/defaults.py
# fixes webroot bug
sed -i '/^OPENSTACK_HOST.*/a WEBROOT = "/dashboard"' /etc/openstack-dashboard/local_settings

sed -i '1iWSGIApplicationGroup %{GLOBAL}' /etc/httpd/conf.d/openstack-dashboard.conf 

# restart services

systemctl restart httpd memcached

exit
