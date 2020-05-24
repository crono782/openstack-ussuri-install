#!/bin/sh

# example of console bootstrap of hostname and first nic

read -p 'hostname: ' bshn;read -p 'int: ' bsint;read -p 'ip/mask: ' bsip;echo setting hostname;hostnamectl set-hostname $bshn;echo setting ip;nmcli con mod $bsint ipv4.address $bsip;echo rebooting system;reboot

# example of bootstrap of second nic

read -p 'int: ' bsint;read -p 'ip/mask: ' bsip;echo removing old connection;nmcli con del 'Wired connection 1';echo setting ip;nmcli con add type ethernet ifname $bsint con-name $bsint ipv4.method manual ipv4.address $bsip ipv4.never-default true ipv6.method ignore

# example of bootstrap of provider third (provider) nic

read -p 'int: ' bsint;echo removing old connection;nmcli con del 'Wired connection 2';echo setting interface;nmcli con add type ethernet ifname $bsint con-name $bsint ipv4.method disabled ipv6.method ignore

# make life simple. clone repo and setup openstack node (not ceph)

curl -o ~/os-env https://raw.githubusercontent.com/crono782/openstack-ussuri-install/master/part-00-setup/os-env
curl https://raw.githubusercontent.com/crono782/openstack-ussuri-install/master/part-00-setup/01-all-nodes-setup.sh|bash

#dnf -y install git
#cd ~
#git clone https://github.com/crono782/openstack-ussuri-install.git
#cp ~/openstack-ussuri-install/part-00-setup/os-env ~
#~/openstack-ussuri-install/part-00-setup/01-all-nodes-setup.sh

# make life simple. clone repo and setup ceph node (not openstack)
curl -o ~/os-env https://raw.githubusercontent.com/crono782/openstack-ussuri-install/master/part-00-setup/os-env

exit
