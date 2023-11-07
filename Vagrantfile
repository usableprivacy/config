Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.provision "shell", path: "conf/vagrant/requirements.sh"
  config.vm.provision "shell", path: "install.sh"
  config.vm.network "forwarded_port", guest: 80, host: 8053
end