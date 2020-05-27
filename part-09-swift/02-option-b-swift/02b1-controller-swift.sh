#!/bin/bash

source ~/os-env

# create user, add role, create services and endpoints

source ~/adminrc

./endpoint.sh object-store 8080/v1/AUTH_%\(project_id\)s

# install packages

dnf -y install openstack-swift-proxy python3-swiftclient python3-keystoneclient python3-keystonemiddleware memcached

# archive old proxy-server.conf file

cp -p /etc/swift/proxy-server.conf /etc/swift/proxy-server.conf.orig

# download new proxy-server.conf file

curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/stable/ussuri/etc/proxy-server.conf-sample

# swap pipelines before working on conf file

sed -i -e '/^pipeline/ s/^p/#p/' -e '/^#pipeline.*authtoken/ s/^#//' /etc/swift/proxy-server.conf

# conf file work

./bak.sh /etc/swift/proxy-server.conf

./conf.sh /etc/swift/proxy-server.conf DEFAULT bind_port 8080
./conf.sh /etc/swift/proxy-server.conf DEFAULT user swift
./conf.sh /etc/swift/proxy-server.conf DEFAULT swift_dir /etc/swift
sed -i '/^pipeline/ s/temp[^ ]* //' /etc/swift/proxy-server.conf
./conf.sh /etc/swift/proxy-server.conf app:proxy-server use egg:swift#proxy
./conf.sh /etc/swift/proxy-server.conf app:proxy-server account_autocreate True
./conf.sh /etc/swift/proxy-server.conf filter:keystoneauth use egg:swift#keystoneauth
./conf.sh /etc/swift/proxy-server.conf filter:keystoneauth operator_roles admin,member
./conf.sh /etc/swift/proxy-server.conf filter:authtoken paste.filter_factory keystonemiddleware.auth_token:filter_factory
./conf.sh /etc/swift/proxy-server.conf filter:authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/swift/proxy-server.conf filter:authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/swift/proxy-server.conf filter:authtoken memcached_servers $OS_CONTROLLER_NM:11211
./conf.sh /etc/swift/proxy-server.conf filter:authtoken auth_type password
./conf.sh /etc/swift/proxy-server.conf filter:authtoken project_domain_id default
./conf.sh /etc/swift/proxy-server.conf filter:authtoken user_domain_id default
./conf.sh /etc/swift/proxy-server.conf filter:authtoken project_name service
./conf.sh /etc/swift/proxy-server.conf filter:authtoken username swift
./conf.sh /etc/swift/proxy-server.conf filter:authtoken password $OS_SWIFTPW 
./conf.sh /etc/swift/proxy-server.conf filter:authtoken delay_auth_decision True
./conf.sh /etc/swift/proxy-server.conf filter:cache use egg:swift#memcache
./conf.sh /etc/swift/proxy-server.conf filter:cache memcache_servers $OS_CONTROLLER_NM:11211

exit
