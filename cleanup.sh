#!/bin/bash

. $(dirname "${0}")/common.sh

dir=$(cd `dirname $0`; pwd)
agentconfigdir=$dir/conf


#get public ip
publicipadd=`vagrant ssh-config | grep HostName | awk -F " " '{print $2}'`
#echo $publicipadd

#remove vms
INFO "Remove all vms"
vagrant destroy --force

INFO "Remove vagrantfile"
rm -rf Vagrantfile

#remove private ip from know_host file
#num=`grep 'env.VMSNUM' vms-vars.groovy  | sed 's/env.VMSNUM=//g' | tr -d '["]'`
#for ((i=1; i<=$num; i=i+1))
#do
#ipadd=`grep 'env.VMSIPADDR' vms-vars.groovy  | sed 's/env.VMSIPADDR=//g' | tr -d '["]' | awk -F , '{print $'$i'}'`
#sed -i "/$ipadd/d" /root/.ssh/known_hosts
#done
stagename=$1

[ -f $stagename ] && ERROR "Stage $stagename is not found" || INFO "Start to cleanup Stage $stagename Agent"

agentconfigs=`find $agentconfigdir/* | grep $stagename`
for agentconfig in $agentconfigs
do
ipadd=`cat $agentconfig | grep vmsipadd | awk -F = '{print $2}'`
num=`cat $agentconfig | grep vmsnum | awk -F = '{print $2}'`
  for ((i=1; i<=$num; i=i+1))
  do
  ip=`echo $ipadd  | awk -F , '{print $'$i'}'`
  echo $ip
  sed -i "/$ip/d" /root/.ssh/known_hosts
  done
done

#remove agentconfigfile
if [ "$stagename" != "" ]; then
    rm -rf $agentconfigdir/$stagename*
fi

#remove public ip for know_host file
for i in $publicipadd
do
sed -i "/$i/d" /root/.ssh/known_hosts
done

INFO "Remove vms sucessfully"
