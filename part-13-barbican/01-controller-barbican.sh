#!/bin/bash

source ~/os-env

# create database

./dbcreate.sh barbican barbican ${OS_BARBICANDBPW}

# create user, service, roles, endpoints

source ~/adminrc

openstack user create --domain default --password ${OS_BARBICANPW} barbican

openstack role add --project service --user barbican admin

openstack role create creator

openstack role add --project service --user barbican creator

if [ "$OS_CREATEDEMO" == "TRUE" ]; then
  openstack role add --project demoproject --user demouser creator
fi

openstack service create --name barbican --description "Key Manager" key-manager

./endpoint.sh key-manager 9311

# install packages

dnf -y install openstack-barbican-api python3-barbicanclient

# configure barbican

./bak.sh /etc/barbican/barbican.conf

./conf.sh /etc/barbican/barbican.conf DEFAULT sql_connection mysql+pymysql://barbican:${OS_BARBICANDBPW}@${OS_CONTROLLER_NM}/barbican
./conf.sh /etc/barbican/barbican.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/barbican/barbican.conf DEFAULT db_auto_create False
./conf.sh /etc/barbican/barbican.conf DEFAULT host_href http://${OS_CONTROLLER_NM}:9311
./conf.sh /etc/barbican/barbican.conf keystone_authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/barbican/barbican.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/barbican/barbican.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/barbican/barbican.conf keystone_authtoken auth_type password
./conf.sh /etc/barbican/barbican.conf keystone_authtoken project_domain_name default
./conf.sh /etc/barbican/barbican.conf keystone_authtoken user_domain_name default
./conf.sh /etc/barbican/barbican.conf keystone_authtoken project_name service
./conf.sh /etc/barbican/barbican.conf keystone_authtoken username barbican
./conf.sh /etc/barbican/barbican.conf keystone_authtoken password ${OS_BARBICANPW}
./conf.sh /etc/barbican/barbican.conf secretstore namespace barbican.secretstore.plugin
./conf.sh /etc/barbican/barbican.conf secretstore enabled_secretstore_plugins store_crypto
./conf.sh /etc/barbican/barbican.conf crypto namespace barbican.crypto.plugin
./conf.sh /etc/barbican/barbican.conf crypto enabled_crypto_plugins simple_crypto

# generate a new 32 byte, base64 encoded kek value

./conf.sh /etc/barbican/barbican.conf simple_crypto_plugin kek "'$(date|sha256sum|head -c 32|base64)'"

# load database

su -s /bin/sh -c "barbican-manage db upgrade" barbican

# start services

for i in enable start;do systemctl $i openstack-barbican-api;done

# verification

openstack secret store --name mysecret --payload j4=]d21

secrethref=$(openstack secret list --name mysecret -c 'Secret href' -f value)

openstack secret get $secrethref

openstack secret get $secrethref --payload

openstack secret delete $secrethref

unset secrethref

exit
