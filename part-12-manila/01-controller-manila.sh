#!/bin/bash

# create database

./dbcreate.sh manila manila $OS_MANILADBPW

# create user, add role, create services and endpoints

source ~/adminrc

openstack user create --domain default --password $OS_MANILAPW manila

openstack role add --project service --user manila admin

openstack service create --name manila --description "OpenStack Shared File Systems" share

openstack service create --name manilav2 --description "OpenStack Shared File Systems V2" sharev2

./endpoint.sh share 8786/v1/%\(tenant_id\)s

./endpoint.sh sharev2 8786/v2/%\(tenant_id\)s

# install packages

dnf -y install openstack-manila python3-manilaclient

# conf file work

./bak.sh /etc/manila/manila.conf

./conf.sh /etc/manila/manila.conf database connection mysql+pymysql://manila:${OS_MANILADBPW}@${OS_CONTROLLER_NM}/manila
./conf.sh /etc/manila/manila.conf DEFAULT transport_url rabbit://openstack:password@${OS_CONTROLLER_NM}
./conf.sh /etc/manila/manila.conf DEFAULT default_share_type default_share_type
./conf.sh /etc/manila/manila.conf DEFAULT share_name_template share-%s
./conf.sh /etc/manila/manila.conf DEFAULT rootwrap_config /etc/manila/rootwrap.conf
./conf.sh /etc/manila/manila.conf DEFAULT api_paste_config /etc/manila/api-paste.ini
./conf.sh /etc/manila/manila.conf DEFAULT auth_strategy keystone
./conf.sh /etc/manila/manila.conf DEFAULT my_ip $OS_CONTROLLER_IP
./conf.sh /etc/manila/manila.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/manila/manila.conf keystone_authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/manila/manila.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/manila/manila.conf keystone_authtoken auth_type password
./conf.sh /etc/manila/manila.conf keystone_authtoken project_domain_name Default
./conf.sh /etc/manila/manila.conf keystone_authtoken user_domain_name Default
./conf.sh /etc/manila/manila.conf keystone_authtoken project_name service
./conf.sh /etc/manila/manila.conf keystone_authtoken username manila
./conf.sh /etc/manila/manila.conf keystone_authtoken password $OS_MANILAPW
./conf.sh /etc/manila/manila.conf oslo_concurrency lock_path /var/lib/manila/tmp

# populate database

su -s /bin/sh -c "manila-manage db sync" manila

# enable and start services

for i in enable start;do systemctl $i openstack-manila-{api,scheduler};done

exit
