#!/bin/sh

read -p 'hostname: ' bshn;read -p 'int: ' bsint;read -p 'ip/mask: ' bsip;hostnamectl set-hostname $bshn;nmcli con mod $bsint ipv4.address $bsip;reboot
