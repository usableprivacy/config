#!/usr/bin/env bash

# Source: https://github.com/usableprivacy/config
# NysosTech e.U.

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
set -e

# Append common folders to the PATH to ensure that all basic commands are available.
export PATH+=':/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# Basic knot-resolver variables
kresd_repo_script_url=https://pkg.labs.nic.cz/doc/scripts/enable-repo-cznic-labs.sh
kresd_repo_script_path=/tmp/enable-repo-cznic-labs.sh
kresd_device=dns0
kresd_ip=127.0.0.53
kresd_config_file=/etc/knot-resolver/kresd.conf

# Basic up-config variables
up_dir=/opt/up-config
up_git_url=https://github.com/usableprivacy/config.git
up_git_branch=main
up_conf_dir="$up_dir/conf"
up_lib_dir="$up_dir/lib"
up_configured=false
up_first_login_script=/etc/profile.d/00-up-config-init.sh

up_environment=system

# pi-hole specific configuration
pi_hole_installer_path=/usr/local/bin/pihole-installer.sh
export PIHOLE_SKIP_OS_CHECK=true

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
apt-get -qq install -y curl dialog git sqlite3 &>/dev/null

if [ -d "/vagrant" ]; then
  up_conf_dir=/vagrant/conf
  up_lib_dir=/vagrant/lib
  ln -sf /vagrant/install.sh /usr/local/bin/up-config-installer
  up_environment=vagrant
else
  if [ -d "$up_dir" ]; then
    git -C "$up_dir" pull --rebase --force &>/dev/null
  else
    git clone -b "$up_git_branch" "$up_git_url" "$up_dir" &>/dev/null
  fi
  ln -sf "$up_dir/install.sh" /usr/local/bin/up-config-installer
fi

if [ -f "/boot/up.txt" ]; then
  up_environment=upbox
fi

echo "[✓]"

echo -e "\nDetected environment: $up_environment \n"

ln -sf $up_lib_dir/up-config /usr/local/bin/up-config
ln -sf $up_lib_dir/up-config.functions /usr/local/lib/up-config.functions

echo -ne "Setup knot-resolver repo ... \t\t\t"

# Remove legacy knot-resolver repo
legacy_apt_installed=$(dpkg-query -W --showformat='${db:Status-Status}' knot-resolver-release 2>&1) || true
if [[ "$legacy_apt_installed" == "installed" ]]; then
  apt-get remove -y --purge knot-resolver-release > /dev/null 2>&1
fi

curl -sSL "$kresd_repo_script_url" -o "$kresd_repo_script_path"
bash "$kresd_repo_script_path" knot-resolver > /dev/null 2>&1

echo "[✓]"

echo -ne "Install knot-resolver ... \t\t\t"

apt-get -qq update &>/dev/null
apt-get -y install knot-resolver knot-resolver-module-http lua-psl &>/dev/null

if ! nmcli dev show $kresd_device &>/dev/null; then
  nmcli connection add type dummy ifname $kresd_device ipv4.method manual ipv4.addresses $kresd_ip/24 &>/dev/null
fi

echo "[✓]"

echo -ne "Preparing pi-hole setup ... \t\t\t"

mkdir -p /etc/pihole
mkdir -p /etc/dnsmasq.d

if [ -f "/etc/pi-hole/setupVars.conf" ]; then
  mv /etc/pi-hole/setupVars.conf /etc/pi-hole/setupVars.conf.backup
fi

if [ ! -f "/etc/pi-hole/pihole.toml" ]; then
  cp $up_conf_dir/pi-hole/pihole.toml /etc/pihole/pihole.toml
fi

cp $up_conf_dir/pi-hole/02-kresd.conf /etc/dnsmasq.d/

echo "[✓]"

if [ ! -f "$pi_hole_installer_path" ]; then
  curl -sSL https://install.pi-hole.net -o "$pi_hole_installer_path"
  bash "$pi_hole_installer_path" --unattended
  pihole -g
fi

#pihole-FTL --config misc.etc_dnsmasq_d true &>/dev/null
#pihole-FTL --config misc.delay_startup 10 &>/dev/null
#pihole-FTL --config dns.upstreams '[ "127.0.0.53", "127.0.0.53" ]' &>/dev/null
#pihole-FTL --config webserver.port 127.0.0.1:8080o,443os,[::]:443os &>/dev/null
#pihole-FTL --config dns.queryLogging false &>/dev/null
#pihole-FTL --config misc.privacylevel 1 &>/dev/null

#sudo service pihole-FTL restart

sleep 1
sqlite3 /etc/pihole/gravity.db < "$up_conf_dir/pi-hole/unfiltered-group.sql"

echo -ne "Enabling knot-resolver ... \t\t\t"

if ! [ -f "/etc/up.conf" ]; then
    rm -f $kresd_config_file
    cp $up_conf_dir/kresd/mix.conf $kresd_config_file
    chgrp knot-resolver $kresd_config_file
  else
    up_configured=true
fi

systemctl enable --now kresd@1.service &>/dev/null
systemctl enable --now kresd@2.service &>/dev/null

echo "[✓]"

if [ $up_environment = upbox ] && [ $up_configured = false ]; then
  echo "sudo up-config init" > $up_first_login_script
fi

echo -e "\n up-config setup complete [✓]"

echo -e "\nPlease run 'up-config init' to complete the up-box setup."
