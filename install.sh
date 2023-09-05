#!/usr/bin/env bash

# Reset: remove / overwrite specific config options; switch to dhcp; run installer, if box -> reset system password
# up-config: if box -> hook setup script; set system password; set status /opt/up-config/setup
#

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
set -e

# Append common folders to the PATH to ensure that all basic commands are available.
export PATH+=':/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# Basic knot-resolver variables
kresd_deb_url=https://secure.nic.cz/files/knot-resolver/knot-resolver-release.deb
kresd_release_file=/tmp/knot-resolver-release.deb
kresd_apt_list=/etc/apt/sources.list.d/knot-resolver-latest.list
kresd_device=dns0
kresd_ip=127.0.0.53
kresd_config_file=/etc/knot-resolver/kresd.conf

# Basic up-config variables
up_dir=/opt/up-config
up_git_url=https://github.com/usableprivacy/config.git
up_conf_dir="$up_dir/conf"
up_lib_dir="$up_dir/lib"
up_configured=false
up_first_login_script=/etc/profile.d/00-up-config-init.sh

up_environment=system
pi_hole_configured=false
pi_hole_installer_path=/usr/local/bin/pihole-installer.sh

exit_on_error() {
  echo "$1"
  sleep 1
  exit 1
}

if [ "$EUID" -ne 0 ]; then
  exit_on_error "This tool requires root privileges. Try again with \"sudo \"  ..."
fi

if ! nmcli -v &>/dev/null; then
  exit_on_error "NetworkManager (nmcli) not found ..."
fi

echo "
 _   _ ____    ____
| | | |  _ \  | __ )  _____  __
| | | | |_) | |  _ \ / _ \ \/ /
| |_| |  __/  | |_) | (_) >  <
 \___/|_|     |____/ \___/_/\_\\

"

echo -ne "Installing up-config requirements ... \t\t"
apt-get -qq install -y curl dialog git &>/dev/null

if [ -d "/vagrant" ]; then
  up_conf_dir=/vagrant/conf
  up_lib_dir=/vagrant/lib
  ln -sf /vagrant/install.sh /usr/local/bin/up-config-installer
  up_environment=vagrant
else
  if [ -d "$up_dir" ]; then
    git -C "$up_dir" pull --rebase &>/dev/null
  else
    git clone "$up_git_url" "$up_dir" &>/dev/null
  fi
  ln -sf "/$up_dir/install.sh" /usr/local/bin/up-config-installer
fi

if [ -f "/boot/up.txt" ]; then
  up_environment=upbox
fi

echo "[✓]"

echo -e "\nDetected environment: $up_environment \n"

ln -sf $up_lib_dir/up-config /usr/local/bin/up-config
ln -sf $up_lib_dir/up-config.functions /usr/local/lib/up-config.functions

echo -ne "Installing knot-resolver requirements ... \t"
if [ ! -f "$kresd_apt_list" ]; then
  curl -s $kresd_deb_url --output $kresd_release_file
  dpkg -i $kresd_release_file &>/dev/null
  apt-get -qq update
  rm $kresd_release_file
fi

apt-get install -qq -y knot-resolver knot-resolver-module-http lua-psl &>/dev/null

if ! nmcli dev show $kresd_device &>/dev/null; then
  nmcli connection add type dummy ifname $kresd_device ipv4.method manual ipv4.addresses $kresd_ip/24 &>/dev/null
fi

echo "[✓]"

echo -ne "Enabling knot-resolver ... \t\t\t"

if ! [ -f "/etc/up.conf" ]; then
    rm -f $kresd_config_file
    cp $up_conf_dir/kresd/mix.conf $kresd_config_file
  else
    up_configured=true
fi


systemctl enable --now kresd@1.service &>/dev/null
systemctl enable --now kresd@2.service &>/dev/null

echo "[✓]"

echo -ne "Preparing pi-hole setup ... \t\t\t"

mkdir -p /etc/pihole
mkdir -p /etc/dnsmasq.d

if [ -f "/etc/pi-hole/setupVars.conf" ]; then
  pi_hole_configured=True
else
  cp $up_conf_dir/pi-hole/setupVars.conf /etc/pihole/
fi

cp $up_conf_dir/pi-hole/02-kresd.conf /etc/dnsmasq.d/

echo "[✓]"

if [ ! -f "$pi_hole_installer_path" ]; then
  curl -sSL https://install.pi-hole.net -o "$pi_hole_installer_path"
  bash "$pi_hole_installer_path" --unattended
fi

if [ "$pi_hole_configured" = False ]; then
  pihole -a -c
  pihole -a -p setup123
  echo -e "Reset pi-hole web login\t\t[✓]"
fi

echo -e "\n up-config setup complete ⭐"

if [ $up_environment = upbox ] && [ $up_configured = false ]; then
  echo "sudo up-config init" > $up_first_login_script
fi

echo -e "\nPlease run 'up-config init' to complete the up-box setup."
