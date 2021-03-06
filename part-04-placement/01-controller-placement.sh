#!/bin/bash

source ~/os-env

# create placement database

./dbcreate.sh placement placement $OS_PLACEMENTDBPW

# create user, add role, create service and endpoints

openstack user create --domain default --password $OS_PLACEMENTPW placement

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

./endpoint.sh placement 8778

# install packages

dnf -y install openstack-placement-api python3-osc-placement

# conf file work

./bak.sh /etc/placement/placement.conf

./conf.sh /etc/placement/placement.conf api auth_strategy keystone
./conf.sh /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:$OS_PLACEMENTDBPW@$OS_CONTROLLER_NM/placement
./conf.sh /etc/placement/placement.conf keystone_authtoken auth_url http://$OS_CONTROLLER_NM:5000/v3
./conf.sh /etc/placement/placement.conf keystone_authtoken memcached_servers $OS_CONTROLLER_NM:11211
./conf.sh /etc/placement/placement.conf keystone_authtoken auth_type password
./conf.sh /etc/placement/placement.conf keystone_authtoken project_domain_name Default
./conf.sh /etc/placement/placement.conf keystone_authtoken user_domain_name Default
./conf.sh /etc/placement/placement.conf keystone_authtoken project_name service
./conf.sh /etc/placement/placement.conf keystone_authtoken username placement
./conf.sh /etc/placement/placement.conf keystone_authtoken password $OS_PLACEMENTPW

# add config to apache conf. packaging bug still misses this part

cat << EOF >> /etc/httpd/conf.d/00-placement-api.conf
<Directory /usr/bin>
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>
    <IfVersion < 2.4>
        Order allow,deny
        Allow from all
    </IfVersion>
</Directory>
EOF

# sync database and restart apache

su -s /bin/sh -c "placement-manage db sync" placement

systemctl restart httpd

# some verification tests

openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name

exit
