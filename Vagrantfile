# -*- mode: ruby -*-
# vi: set ft=ruby :

# Config Github Settings
github_username = "fideloper"
github_repo     = "Vaprobash"
github_branch   = "1.4.2"
github_url      = "https://raw.githubusercontent.com/#{github_username}/#{github_repo}/#{github_branch}"

# Because this:https://developer.github.com/changes/2014-12-08-removing-authorizations-token/
# https://github.com/settings/tokens
github_pat          = ""

# Server Configuration

hostname        = "vaprobash.dev"

# Set a local private network IP address.
# See http://en.wikipedia.org/wiki/Private_network for explanation
# You can use the following IP ranges:
#   10.0.0.1    - 10.255.255.254
#   172.16.0.1  - 172.31.255.254
#   192.168.0.1 - 192.168.255.254
server_ip             = "192.168.22.90"
server_cpus           = "1"   # Cores
server_memory         = "384" # MB
server_swap           = "768" # Options: false | int (MB) - Guideline: Between one or two times the server_memory

# UTC        for Universal Coordinated Time
# EST        for Eastern Standard Time
# CET        for Central European Time
# US/Central for American Central
# US/Eastern for American Eastern
server_timezone  = "UTC"

# Database Configuration
mysql_root_password   = "vagrant"   # We'll assume user "vagrant"
mysql_version         = "5.6"    # Options: 5.5 | 5.6
mysql_enable_remote   = "false"  # remote access enabled when true
pgsql_root_password   = "vagrant"   # We'll assume user "vagrant"

# Languages and Packages
php_timezone          = "UTC"    # http://php.net/manual/en/timezones.php
php_version           = "7.0"    # Options: 5.5 | 5.6 | 7.0
hhvm                  = "false"
public_folder         = "/var/www"
composer_packages     = []

go_version            = "latest" # Example: go1.4 (latest equals the latest stable version)

nodejs_version        = "latest"   # By default "latest" will equal the latest stable version
nodejs_packages       = [          # List any global NodeJS packages that you want to install
  #"yo",
]

# RabbitMQ settings
rabbitmq_user = "user"
rabbitmq_password = "password"

elasticsearch_version = "5.0.1" # 5.0.1, 2.3.1, 2.2.2, 2.1.2, 1.7.5

Vagrant.configure("2") do |config|

  # Set server to Ubuntu 14.04
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "Vaprobash" do |vapro|
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  # Create a hostname, don't forget to put it to the `hosts` file
  # This will point to the server's default virtual host
  # TO DO: Make this work with virtualhost along-side xip.io URL
  config.vm.hostname = hostname

  # Create a static IP
  if Vagrant.has_plugin?("vagrant-auto_network")
    config.vm.network :private_network, :ip => "0.0.0.0", :auto_network => true
  else
    config.vm.network :private_network, ip: server_ip
    config.vm.network :forwarded_port, guest: 80, host: 8000
  end

  # Enable agent forwarding over SSH connections
  config.ssh.forward_agent = true

  # Use NFS for the shared folder
  config.vm.synced_folder ".", "/var/www" #, type: "rsync", rsync__exclude: ".git/", rsync__auto: "true"

  # Replicate local .gitconfig file if it exists
  if File.file?(File.expand_path("~/.gitconfig"))
    config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
  end

  # If using VirtualBox
  config.vm.provider :virtualbox do |vb|

    vb.name = hostname

    # Set server cpus
    vb.customize ["modifyvm", :id, "--cpus", server_cpus]

    # Set server memory
    vb.customize ["modifyvm", :id, "--memory", server_memory]

    # Set the timesync threshold to 10 seconds, instead of the default 20 minutes.
    # If the clock gets more than 15 minutes out of sync (due to your laptop going
    # to sleep for instance, then some 3rd party services will reject requests.
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]

    # Prevent VMs running on Ubuntu to lose internet connection
    # vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

  end

  # If using VMWare Fusion
  config.vm.provider "vmware_fusion" do |vb, override|
    override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"

    # Set server memory
    vb.vmx["memsize"] = server_memory

  end

  # If using Vagrant-Cachier
  # http://fgrehm.viewdocs.io/vagrant-cachier
  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # Usage docs: http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box

  end

  ####
  # Base Items
  ##########

  # Provision Base Packages
  config.vm.provision "shell", path: "./scripts/base.sh", args: [github_url, server_swap, server_timezone]

  # optimize base box
  config.vm.provision "shell", path: "./scripts/base_box_optimizations.sh", privileged: true

  # Provision PHP
  config.vm.provision "shell", path: "./scripts/php.sh", args: [php_timezone, hhvm, php_version]

  # Provision Vim
  # config.vm.provision "shell", path: "./scripts/vim.sh", args: github_url

  # Provision Docker
  # config.vm.provision "shell", path: "./scripts/docker.sh", args: "permissions"

  ####
  # Web Servers
  ##########

  # Provision Nginx Base
   config.vm.provision "shell", path: "./scripts/nginx.sh", args: [server_ip, public_folder, hostname, github_url]


  ####
  # Databases
  ##########

  # Provision MySQL
  # config.vm.provision "shell", path: "./scripts/mysql.sh", args: [mysql_root_password, mysql_version, mysql_enable_remote]

  # Provision PostgreSQL
   config.vm.provision "shell", path: "./scripts/pgsql.sh", args: pgsql_root_password

  ####
  # Search Servers
  ##########

  # Install Elasticsearch
   config.vm.provision "shell", path: "./scripts/elasticsearch.sh", args: [elasticsearch_version]

  ####
  # Search Server Administration (web-based)
  ##########

  # Install ElasticHQ
  # Admin for: Elasticsearch
  # Works on: Apache2, Nginx
   config.vm.provision "shell", path: "./scripts/elastichq.sh"


  ####
  # In-Memory Stores
  ##########

  # Provision Redis (without journaling and persistence)
   config.vm.provision "shell", path: "./scripts/redis.sh"

  # Provision Redis (with journaling and persistence)
  # config.vm.provision "shell", path: "./scripts/redis.sh", args: "persistent"
  # NOTE: It is safe to run this to add persistence even if originally provisioned without persistence


  ####
  # Utility (queue)
  ##########

  # Install Kibana
   config.vm.provision "shell", path: "./scripts/kibana.sh"

  # Install RabbitMQ
  config.vm.provision "shell", path: "./scripts/rabbitmq.sh", args: [rabbitmq_user, rabbitmq_password]

  ####
  # Additional Languages
  ##########

  # Install Nodejs
   config.vm.provision "shell", path: "./scripts/nodejs.sh", privileged: false, args: nodejs_packages.unshift(nodejs_version, github_url)

  ####
  # Frameworks and Tooling
  ##########

  # Provision Composer
  # You may pass a github auth token as the first argument
   config.vm.provision "shell", path: "./scripts/composer.sh", privileged: false, args: [github_pat, composer_packages.join(" ")]

  # Install Mailcatcher
  # config.vm.provision "shell", path: "./scripts/mailcatcher.sh"


  ####
  # Local Scripts
  # Any local scripts you may want to run post-provisioning.
  # Add these to the same directory as the Vagrantfile.
  ##########
  # config.vm.provision "shell", path: "./crm-setup.sh"

end
