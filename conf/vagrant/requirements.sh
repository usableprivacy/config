#!/usr/bin/env bash

# Script to prepare vagrant (debian) for up-config

apt-get update && apt-get upgrade -y
apt-get install curl git network-manager shellcheck -y
sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
sed -i 's/iface\ eth0\ inet\ dhcp/auto\ eth0/g' /etc/network/interfaces
service networking stop
systemctl start NetworkManager.service && systemctl enable NetworkManager.service
service NetworkManager restart
echo -en "de_AT.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen