#!/bin/bash
# enable cinder backups for swift

source ~/os-env

# ensure package installed

dnf -y install openstack-cinder

# conf file work

./conf.sh /etc/cinder/cinder.conf DEFAULT backup_driver cinder.backup.drivers.swift.SwiftBackupDriver
./conf.sh /etc/cinder/cinder.conf DEFAULT backup_swift_url http://${OS_CONTROLLER_NM}:8080/v1/AUTH_

# enable and start backup service

for i in enable start;do systemctl $i openstack-cinder-backup;done

exit
