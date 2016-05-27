# -*- mode: ruby -*-
# vi: set ft=ruby :

# A dummy plugin for Barge to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

VM_IP_ADDR = "10.0.23.16"
DNS_DOMAIN = "test"
DOCKER_NET = "172.17.0.0/16"
DOCKER0_IP = "172.17.0.1"

Vagrant.configure(2) do |config|
  config.vm.define "wocker"
  config.vm.box = "ailispaw/barge"
  config.vm.box_version = ">= 2.2.1"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  end

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Setup DNS resolver and routing to #{DNS_DOMAIN} domain."
      run <<-EOT
        sh -c "sudo mkdir -p /etc/resolver && \
          echo nameserver #{VM_IP_ADDR} | sudo tee /etc/resolver/#{DNS_DOMAIN} && \
          sudo route -n add -net #{DOCKER_NET} #{VM_IP_ADDR}"
      EOT
    end

    config.trigger.after [:destroy, :suspend, :halt] do
      info "Remove DNS resolver and routing to #{DNS_DOMAIN} domain."
      run <<-EOT
        sh -c "sudo rm -f /etc/resolver/#{DNS_DOMAIN} && \
          sudo route -n delete -net #{DOCKER_NET} #{VM_IP_ADDR}"
      EOT
    end
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  if Vagrant.has_plugin?("vagrant-hostsupdater")
    config.hostsupdater.remove_on_suspend = true
  end

  config.vm.hostname = "wocker.#{DNS_DOMAIN}"
  config.vm.network :private_network, ip: "#{VM_IP_ADDR}", hostsupdater: "skip"

  config.vm.synced_folder "./data", "/home/bargee/data", create: true,
    mount_options: ["iocharset=utf8"]

  config.vm.provision :shell do |sh|
    sh.inline = <<-EOT
      echo 'DOCKER_EXTRA_ARGS="--userland-proxy=false \
        --bip=#{DOCKER0_IP}/16 --dns=#{DOCKER0_IP}"' >> /etc/default/docker
      /etc/init.d/docker restart
    EOT
  end

  config.vm.provision :docker do |d|
    d.pull_images "ailispaw/dnsdock"
    d.run "dnsdock",
      image: "ailispaw/dnsdock",
      args: "-v /var/run/docker.sock:/var/run/docker.sock -p 0.0.0.0:53:53/udp",
      cmd: "--domain=#{DNS_DOMAIN}"
  end

  config.vm.provision :shell do |sh|
    sh.inline = <<-EOT
      echo "nameserver 127.0.0.1" > /etc/resolv.conf.head
      dhcpcd -x eth0 && dhcpcd eth0
    EOT
  end

  config.vm.provision :shell, path: "provision.sh", privileged: false

  config.vm.provision :shell, path: "wocker-multi.sh"

  config.vm.provision :shell, inline: "wocker-multi wocker #{DNS_DOMAIN}",
    privileged: false, run: "always"
end
