#!/bin/bash

source ~/os-env

# install packages

dnf -y --enablerepo=PowerTools install openstack-dashboard

# config work

cp -p /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.bkp
cp -p /usr/share/openstack-dashboard/openstack_dashboard/defaults.py /usr/share/openstack-dashboard/openstack_dashboard/defaults.py.bkp

# configure horizon

sed -i "s/^OPENSTACK_HOST.*/OPENSTACK_HOST = \"$OS_CONTROLLER_NM\"/" /etc/openstack-dashboard/local_settings
sed -i "s/^ALLOWED_HOSTS.*/ALLOWED_HOSTS = ['*']/" /etc/openstack-dashboard/local_settings
sed -i "/^#CACHES/,/\}$/{s/^#//;s/127.0.0.1/$OS_CONTROLLER_NM/}" /etc/openstack-dashboard/local_settings
sed -i "s/#\+SESSION_ENGINE.*/SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/" /etc/openstack-dashboard/local_settings 
sed -i 's/^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "member"/' /usr/share/openstack-dashboard/openstack_dashboard/defaults.py
# fixes webroot bug
sed -i '/^OPENSTACK_HOST.*/a WEBROOT = "/dashboard"' /etc/openstack-dashboard/local_settings
sed -i "s|^POLICY_FILES_PATH.*|POLICY_FILES_PATH = '/etc/openstack-dashboard'|" /usr/share/openstack-dashboard/openstack_dashboard/defaults.py

# set up redirection

sed -i '/^WSGISocketPrefix/d' /etc/httpd/conf.d/openstack-dashboard.conf
sed -i '1iWSGIApplicationGroup %{GLOBAL}' /etc/httpd/conf.d/openstack-dashboard.conf 
#sed -i '1iRedirectMatch permanent  ^/$ /dashboard' /etc/httpd/conf.d/openstack-dashboard.conf 
sed -i '1i<VirtualHost *:80>' /etc/httpd/conf.d/openstack-dashboard.conf 
sed -i '1iWSGISocketPrefix run/wsgi' /etc/httpd/conf.d/openstack-dashboard.conf
echo '</VirtualHost>' >> /etc/httpd/conf.d/openstack-dashboard.conf 
# restart services

systemctl restart httpd memcached

# login to http://<controller> to test horizon
# admin/<specified admin password> OR
# demouser/password if specified

exit
