#!/bin/bash

source ~/os-env

# create user, add role, create services and endpoints

source ~/adminrc

openstack user create --domain default --password $OS_SWIFTPW swift

openstack role add --project service --user swift admin

openstack service create --name swift --description "OpenStack Object Storage" object-store

exit
