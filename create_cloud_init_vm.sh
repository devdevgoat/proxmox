#!/bin/bash

# PVE Vars
isoFolder='/mnt/pve/ISOs/template/iso'
lvmName='LVM_THIN_4TB'
maxVMID=$(pvesh get /cluster/resources --type vm --output-format yaml | egrep -i 'vmid' | cut -d \: -f 2 | xargs -n1 | sort -rn | xargs | cut -d ' ' -f 1)
nextVMID=$((maxVMID+1))
while getopts f:c:m: flag
do
    case "${flag}" in
        f) filename=${OPTARG};;
        c) cpu=${OPTARG};;
        m) memory=${OPTARG};;
    esac
done
# echo $filename
# echo $vmid
echo "Filename: $filename"
echo "cpu: $cpu "
echo "memory: $memory"
echo "Found largest VM id of ${maxVMID}, incrementing to ${nextVMID}"
vmid=$nextVMID

isoFullPath="${isoFolder}/${filename}"
# isoFullPath="${filename}"
echo "Attempted to build cloud init from img ${isoFullPath}..."
qm create $vmid --cores $cpu --memory $memory --name ${filename:0:12}-${cpu}CPU-${memory}RAM --net0 virtio,bridge=vmbr0

echo "Created VM ${vmid}. Transfering Img..."
diskName=$(qm importdisk ${vmid} ${isoFullPath} ${lvmName} | grep -Po '${lvmName}:(.*)')

echo "Transfered image with disk name '${diskName}'. Attaching..."
qm set ${vmid} --scsihw virtio-scsi-pci --scsi0 ${diskName::-1}

echo "Adding CloudInit drive..."
qm set ${vmid} --ide2 ${lvmName}:cloudinit

echo "Setting boot disk..."
qm set ${vmid} --boot c --bootdisk scsi0

echo "Enabling vnc serial"
qm set ${vmid} --serial0 socket --vga serial0

echo "Configuring SSH for windows and macbook"
qm set ${vmid} --sshkey "/etc/pve/pub_keys/id_rsa - rw11.pub"
#qm set ${vmid} --sshkey "/etc/pve/pub_keys/id_rsa - macbook.pub"

echo "Configuring Ip to use DCHP"
qm set ${vmid} --ipconfig0 ip=dhcp

echo 'DONE! '