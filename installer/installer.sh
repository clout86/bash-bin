#!/bin/bash

chroot="/mnt/gentoo"



echo "Available drives:"
# maybe your virtual machine has a floppy device?
lsblk -n | grep -v fd[0-9] | grep disk
first=$(lsblk -n | grep -v fd[0-9] | grep disk | head -1 | awk '{print $1}')

while :; do
    echo
    echo "Script will partition drive and DESTROY all data"
    read -erp "Select drive, first one detected is:/dev/${first}: " drive
    echo "Dirve $drive was selected"
    read -erp "Is this okay?" -n 1 isokay
    if [[ $isokay == "Y" ]]; then
        break
    else
        echo "invalid option: must be Y"
    fi
done

sdx_d(){
bootfs="${drive}1"
swapfs="${drive}2"
rootfs="${drive}3"
}

nvme_d(){
bootfs="/dev/${drive}p1"
swapfs="/dev/${drive}p2"
rootfs="/dev/${drive}p3"
}

if echo $drive | grep sd[a-z] > /dev/null; then
        echo "is scsi based drive"
        sdx_d
    elif echo $drive | grep nvme[0-9][a-z][0-9] 2> /dev/null; then
        echo "is pci-e drive"
        nvme_d
    else
    echo "No compatible drive configurations"
    exit
fi

bfss="1MiB"; bfse="512MiB"
sfss="${bfse}"; sfse="1536MiB"
rfss="${sfse}"; rfse="100%"

cat << EOF
Partions to be created:

${bootfs} fat32 $bfss $bfse Boot/EFI system partition
${swapfs} (swap) $sfss $sfse Swap partition
${rootfs}  ext4 $rfss $rfse / Rootfs
EOF

pure_uefi(){
    parted --script -a optimal $drive \
    mklabel gpt \
    mkpart primary fat32 ${bfss} ${bfse} set 1 esp on name 1 boot \
    mkpart primary linux-swap ${sfss} ${sfse} name 2 swap \
    mkpart primary ext4 ${rfss} ${rfse} name 3 rootfs

    mkfs.fat -F 32 ${bootfs}
    mkfs.ext4 ${rootfs}
    mkswap ${swapfs}
    swapon ${swapfs}
}
# things to do:
time_check(){
    date # ask if good.
    ntpd -q -g # run if prompted.
    date # ask to varify.
    echo "Enter to continue"
    read
}; #time_check
lsblk
echo "mounting ${rootfs} ${chroot} [enter]"
read
mount ${rootfs} ${chroot}
#get-stage(){
#    builddate=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/ \
#    | sed -nr "s/.*href=\"stage3-amd64-([0-9].*).tar.xz\">.*/\1/p")
#
#    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-$builddate.tar.xz
#    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-$builddate.tar.xz.DIGESTS
#    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-$builddate.tar.xz.DIGESTS.asc
#
#    check_downloads(){
#        openssl dgst -r -sha512 stage3-amd64-${builddate}.tar.xz
#        sha512sum stage3-amd64-${builddate}.tar.xz
#        openssl dgst -r -whirlpool stage3-amd64-${builddate}.tar.xz
#        gpg --verify stage3-amd64-${builddate}.tar.xz.DIGESTS.asc
#    }
#}
#
cp -v /root/stage3* ${chroot}
cd ${chroot} 
pwd
echo "will now unpack stage [enter]"
read
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner || exit $?

#rm -f stage3*

cp -v --dereference /etc/resolv.conf ${chroot}/etc/

mount_targetfs(){
    mount -t proc none proc
    mount --rbind /sys sys
    mount --make-rslave sys
    mount --rbind /dev dev
    mount --make-rslave dev
    cd -
}; mount_targetfs


#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

chroot ${chroot} /bin/bash
