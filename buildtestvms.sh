#!/bin/bash

. $(dirname "${0}")/common.sh

set -e # exit on an error

#if [ -f Vagrantfile ];then
#  ERROR "vagrantfile is existed, pls remove the vagrantfile"
#  exit 0
#fi

box="centos7.6"
if [ "$1" != "" ];then
   echo $1
   box=$1 
fi
#create a vagrant file
INFO "Generating Vagrantfile"
num=`grep 'env.VMSNUM' vms-vars.groovy  | sed 's/env.VMSNUM=//g' | tr -d '["]'`
echo "servers = {" > Vagrantfile
for ((i=1; i<=$num; i=i+1))
do
ipadd=`grep 'env.VMSIPADDR' vms-vars.groovy  | sed 's/env.VMSIPADDR=//g' | tr -d '["]' | awk -F , '{print $'$i'}'`
nodename=`grep 'env.VMSNODENAME' vms-vars.groovy  | sed 's/env.VMSNODENAME=//g' | tr -d '["]' | awk -F , '{print $'$i'}'`
if [ "$ipadd" = "" ];then
     exit 1
fi
echo "     :$nodename" "=>" "'$ipadd'," >> Vagrantfile
done
echo "}" >> Vagrantfile

cat >> Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.box = "$box"
  
  servers.each do |server_name, server_ip|
      config.vm.define server_name do |server_config|
          server_config.vm.hostname = "#{server_name.to_s}"
          server_config.vm.network :private_network, ip: server_ip
          server_config.vm.provider "libvirt" do |vb|
              vb.memory = "2048"
              vb.cpus = 4
              vb.storage :file, :size => '20G'
          end
          server_config.vm.provision "shell",
            inline: <<-SHELL
              echo -e "root123\nroot123" | passwd root
              sed -in "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
              sed -in "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
              systemctl restart sshd
          SHELL
      end
  end
end      
EOF

#virsh list
vagrant up 
INFO "Create VM successfully"







