Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.define "up-config-vagrant"
  config.vm.provision "shell", path: "conf/vagrant/requirements.sh"
  config.vm.provision "shell", path: "install.sh"
  config.vm.network "forwarded_port", guest: 443, host: 8443
  config.vm.network "forwarded_port", guest: 53, host: 5353
end