#!/bin/sh

# example of console bootstrap of hostname and first nic

read -p 'hostname: ' bshn;read -p 'int: ' bsint;read -p 'ip/mask: ' bsip;echo setting hostname;hostnamectl set-hostname $bshn;echo setting ip;nmcli con mod $bsint ipv4.address $bsip;echo rebooting system;reboot

# example of bootstrap of second nic

read -p 'int: ' bsint;read -p 'ip/mask: ' bsip;echo removing old connection;nmcli con del 'Wired connection 1';echo setting ip;nmcli con add type ethernet ifname $bsint con-name $bsint ipv4.method manual ipv4.address $bsip ipv4.never-default true ipv6.method ignore

# example of bootstrap of provider third (provider) nic

read -p 'int: ' bsint;echo removing old connection;nmcli con del 'Wired connection 2';echo setting interface;nmcli con add type ethernet ifname $bsint con-name $bsint ipv4.method disabled ipv6.method ignore
