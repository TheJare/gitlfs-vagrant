# -*- mode: ruby -*-
# vi: set ft=ruby :
# Based on Gitlab-installer https://github.com/tuminoid/gitlab-installer

# read settings from environment variables
memory = ENV['GITLFS_MEMORY'] || 1024
cpus = ENV['GITLFS_CPUS'] || 1
port = ENV['GITLFS_PORT'] || 8443
host = ENV['GITLFS_HOST'] || "gitlfs.local"
admin = ENV['GITLFS_ADMIN_USER'] || "admin"
adminpw = ENV['GITLFS_ADMIN_PASSWORD'] || "admin"

Vagrant.require_version ">= 1.5.0"

Vagrant.configure("2") do |config|

  config.vm.define :gitlfs do |config|
    # Configure some hostname here
    config.vm.hostname = host
    config.vm.box = "ubuntu/xenial64"
    config.vm.provision :shell, :path => "install.sh",
      env: { "GITLFS_HOSTNAME" => host, "GITLFS_PORT" => port,
             "GITLFS_ADMIN_USER" => admin, "GITLFS_ADMIN_PASSWORD" => adminpw }

    config.vm.network :forwarded_port, guest: 443, host: port
  end

  config.vm.provider "virtualbox" do |v, override|
    v.cpus = cpus
    v.memory = memory
  end

  #
  # These below are untested
  #

  config.vm.provider "vmware_fusion" do |v, override|
    v.vmx["memsize"] = "#{memory}"
    v.vmx["numvcpus"] = "#{cpus}"
    override.vm.box = "puppetlabs/ubuntu-16.04-64-puppet"
  end

  config.vm.provider "parallels" do |v, override|
    v.cpus = cpus
    v.memory = memory
    # waiting for official "parallels/ubuntu-16.04" vm
    override.vm.box = "boxcutter/ubuntu1604"
  end

  config.vm.provider "lxc" do |v, override|
    override.vm.box = "developerinlondon/ubuntu_lxc_xenial_x64"
  end
end
