#!/bin/bash

source ~/os-env

# create database

./dbcreate.sh heat heat $OS_HEATDBPW

# create projects, users, roles, domains, endpoints, etc

source ~/adminrc

openstack user create --domain default --password $OS_HEATPW heat

openstack role add --project service --user heat admin

openstack service create --name heat --description "Orchestration" orchestration

openstack service create --name heat-cfn --description "Orchestration"  cloudformation

./endpoint.sh orchestration 8004/v1/%\(project_id\)s

./endpoint.sh cloudformation 8000/v1

openstack domain create --description "Stack projects and users" heat

openstack user create --domain heat --password $OS_HEATDAPW heat_domain_admin

openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

openstack role create heat_stack_owner

if [ "$OS_CREATEDEMO" == "TRUE" ]; then
  openstack role add --project demoproject --user demouser heat_stack_owner
fi

openstack role create heat_stack_user

# install packages

dnf -y install openstack-heat-api openstack-heat-api-cfn openstack-heat-engine

# conf file work

./bak.sh /etc/heat/heat.conf

./conf.sh /etc/heat/heat.conf database connection mysql+pymysql://heat:${OS_HEATDBPW}@${OS_CONTROLLER_NM}/heat
./conf.sh /etc/heat/heat.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://${OS_CONTROLLER_NM}:8000
./conf.sh /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://${OS_CONTROLLER_NM}:8000/v1/waitcondition
./conf.sh /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
./conf.sh /etc/heat/heat.conf DEFAULT stack_domain_admin_password $OS_HEATDAPW
./conf.sh /etc/heat/heat.conf DEFAULT stack_user_domain_name heat
./conf.sh /etc/heat/heat.conf keystone_authtoken auth_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/heat/heat.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/heat/heat.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/heat/heat.conf keystone_authtoken auth_type password
./conf.sh /etc/heat/heat.conf keystone_authtoken project_domain_name default
./conf.sh /etc/heat/heat.conf keystone_authtoken user_domain_name default
./conf.sh /etc/heat/heat.conf keystone_authtoken project_name service
./conf.sh /etc/heat/heat.conf keystone_authtoken username heat
./conf.sh /etc/heat/heat.conf keystone_authtoken password $OS_HEATPW
./conf.sh /etc/heat/heat.conf trustee auth_type password
./conf.sh /etc/heat/heat.conf trustee auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/heat/heat.conf trustee username heat
./conf.sh /etc/heat/heat.conf trustee password $OS_HEATPW
./conf.sh /etc/heat/heat.conf trustee user_domain_name default
./conf.sh /etc/heat/heat.conf clients_keystone auth_uri http://${OS_CONTROLLER_NM}:5000

# populate database

su -s /bin/sh -c "heat-manage db_sync" heat

# enable and start services

for i in enable start;do systemctl $i openstack-heat-{api{,-cfn},engine};done

# verifications

source ~/adminrc

openstack orchestration service list

# install heat dashboard packages

dnf -y install openstack-heat-ui

# reload apache

systemctl restart httpd

exit
