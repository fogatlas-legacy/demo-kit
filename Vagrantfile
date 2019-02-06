# -*- mode: ruby -*-
# vi: set ft=ruby :

# Variables
NODES = 3
NODES_NET_PREFIX = '192.168.77'
OS_IMAGE = 'ubuntu/xenial64'
PLAYBOOK = 'k8s_cluster.yml'
DEBUG = false

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  # Do not update guest addition on the guest
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end
  config.ssh.insert_key = false

  config.vm.box = OS_IMAGE

  host_vars = {}

  (1..NODES).each do |machine_id|
    config.vm.define "k8s-node-#{machine_id}" do |machine|
      machine.vm.hostname = "k8s-node-#{machine_id}"
      machine.vm.network "private_network", ip: "#{NODES_NET_PREFIX}.#{10+machine_id}"

      # Expose foggy API server of the master_ip
      if machine_id == 1
        machine.vm.network "forwarded_port", guest: 30003, host: 30003, host_ip: "127.0.0.1"
        machine.vm.network "forwarded_port", guest: 30004, host: 30004, host_ip: "127.0.0.1"
        machine.vm.network "forwarded_port", guest: 30005, host: 30005, host_ip: "127.0.0.1"
      end

      # Set resources for nodes in different regions
      machine.vm.provider :virtualbox do |v|
        case machine_id
        when 1
          # K8S Master
          v.memory = 1024
          v.cpus = 1
        when 2
          # Cloud node
          v.memory = 1024
          v.cpus = 2
        when 3
          # Fog node
          v.memory = 512
          v.cpus = 1
        end
      end

      # Set IP of the master node
      # Set node IP used by kubelet
      host_vars[machine.vm.hostname] = {"kubeadm_master_ip" => "#{NODES_NET_PREFIX}.11",
                                        "kubelet_node_ip" => "#{NODES_NET_PREFIX}.#{10+machine_id}"}


      # Only execute once the Ansible provisioner,
      # when all the machines are up and ready.
      if machine_id == NODES
        # Install k8s
        machine.vm.provision :ansible do |ansible|
          ansible.groups = {
            "k8s-master" => ["k8s-node-1"],
            "k8s-workers" => ["k8s-node-[2:#{NODES}]"]
          }

          ansible.host_vars = host_vars
          ansible.limit = "all"
          ansible.playbook = PLAYBOOK
          if DEBUG
            ansible.verbose ="vvv"
          end
        end
      end

    end
  end
end
