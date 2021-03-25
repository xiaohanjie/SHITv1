#!/bin/bash 

. $(dirname "${0}")/common.sh
set -e # exit on an error

#dir=$(cd `dirname $0`; pwd)
dir=$WORKSPACE_PATH
agentconfigdir=$dir/conf
vagrant=$dir/Vagrantfile

echo $dir
echo $agentconfigdir
echo $vagrant

#init default vagrant
vmsboxname="ubuntu"
vmsboxversion="1604"
vmsnum=1
vmsipadd="192.168.2.28"
vmsnodename="client1"
vmsusername="root"
vmspassword="root123"
vmsagentname="client"


[ -f $vagrant ] && echo "Vagrantfile is existed" || touch $vagrant

function CheckVMSAgentStatus() {
    local agentname=$1
    if [ "$agentname" == "" ]; then
        ERROR "agentname is required in the argument"
        exit 1
    fi

    local isexist=`cat $vagrant | grep $agentname.each`
    if [ "$isexist" != "" ]; then
        ERROR "agentname is existed in this stage, pls change a differenet agentname. "
        exit 1
    fi
}

function CheckVMSNICStatus() {
    local ip=$1
    for ((i=1; i<=$vmsnum; i=i+1))
    do
       ip=`echo $ip | awk -F , '{print $'$i'}'`
       ping -c2 -i0.3 -W1 $ip &>/dev/null
       if [ $? -eq 0 ]; then
          ERROR "ip address $ip is up, pls change vms private address"
          exit 1
       fi
    done
}

function CheckVMSBoxStatus() {
    local boxname=$1
    local isexist=`vagrant box list | grep $boxname`
    if [ "$isexist" == "" ]; then
        ERROR "box $boxname isnot found in box list, pls add this box in vagrant"
        exit 1
    fi 
}


function SetVMSVariables() {
    local agentname=$1
    #cat $agentconfigdir/$agentname | grep vmsagentname | awk -F = '{print $2}'
    agentconfigpath=$agentconfigdir/$agentname
    [ -f $agentconfigpath ] && echo "agentconfigfile $agentconfigpath is existed" || ERROR " agentconfigfile is not found"
    testtext=`cat $agentconfigpath`
    for i in $testtext
    do 
       key=`echo $i | awk -F = '{print $1}'`
       value=`echo $i | awk -F = '{print $2}'`
       eval $key=`echo $value` 
    done
    echo $vmsagentname
    echo $vmsboxname
    echo $vmsboxversion
    echo $vmsipadd
    echo $vmsnodename
    echo $vmsnum
    echo $vmsusername
    echo $vmspassword
}

agentname=$1

SetVMSVariables $agentname 
#CheckVMSAgentStatus $vmsagentname
#CheckVMSBoxStatus $vmsboxname$vmsboxversion
#CheckVMSNICStatus $vmsipadd


#create a vagrant file
INFO "Generating Vagrantfile"
echo "$vmsagentname = {" >> $vagrant
for ((i=1; i<=$vmsnum; i=i+1))
do
ip=`echo $vmsipadd | awk -F , '{print $'$i'}'`
node=`echo $vmsnodename | awk -F , '{print $'$i'}'`
echo "     :$node" "=>" "'$ip'," >> $vagrant
done
echo "}" >> $vagrant

cat >> $vagrant <<EOF
Vagrant.configure("2") do |config|
  $vmsagentname.each do |vms_name, vms_ip|
      config.vm.define vms_name do |vms_config|
          vms_config.vm.boot_timeout = 200
          vms_config.vm.box = "$vmsboxname$vmsboxversion"
          vms_config.vm.hostname = "#{vms_name.to_s}"
          vms_config.vm.network :private_network, ip: vms_ip
          vms_config.vm.provider "libvirt" do |vb|
              vb.memory = "2048"
              vb.cpus = 4
              vb.storage :file, :size => '20G'
          end
          vms_config.vm.provision "shell",
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
cd $dir; vagrant up
[ $? == 0 ] && INFO "Create VMS successfully" || ERROR "Failed to Create VMS"

