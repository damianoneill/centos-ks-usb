#!/bin/bash
# create custom bootable iso for CentOS 7 with kickstart

[ $# -lt 2 ] && echo "Usage: $0 <iso> <kickstart file>" && exit 1
[ ! -f $1 ] && echo "ISO File $1 does not exist!" && exit 1
[ ! -f $2 ] && echo "Kickstart File $2 does not exist!" && exit 1

# Set Variables
ISO=$1 
KS=$2
TMPDIR=tmp
GENISO=${GENISO:-${1%.iso}-$2}.iso

# install deps
[ ! -f /usr/bin/genisoimage ] && yum install -y genisoimage
[ ! -f /usr/bin/createrepo ] && yum install -y createrepo
[ ! -f /usr/bin/isohybrid ] && yum install -y syslinux
[ ! -f /usr/bin/mkisofs ] && yum install -y mkisofs
[ ! -f /usr/sbin/mkfs.vfat ] && yum install -y dosfstools

# create the tmp directories
mkdir -p $TMPDIR/kickstart/isolinux/{images,ks,LiveOS,Packages}

# mount the centos iso
mkdir -p $TMPDIR/mnt/iso
mount -o loop $ISO $TMPDIR/mnt/iso

# copy content from the centos based iso
cp $TMPDIR/mnt/iso/.discinfo $TMPDIR/kickstart/isolinux/
cp $TMPDIR/mnt/iso/isolinux/* $TMPDIR/kickstart/isolinux/
rsync -av $TMPDIR/mnt/iso/images/ $TMPDIR/kickstart/isolinux/images/
cp $TMPDIR/mnt/iso/LiveOS/* $TMPDIR/kickstart/isolinux/LiveOS/

# find and copy over the comps.xml file
gunzip -c $TMPDIR/mnt/iso/repodata/*-comps.xml.gz > $TMPDIR/kickstart/comps.xml

# copy over all .rpm packages
rsync -av $TMPDIR/mnt/iso/Packages/ $TMPDIR/kickstart/isolinux/Packages/

# unmount the iso
umount $TMPDIR/mnt/iso

# create repodata for the packages copied over so that it could be 
# used for package installation during OS installation
pushd $TMPDIR/kickstart/isolinux
createrepo -g ../comps.xml .
popd 

# Copy over your kickstart file
cp $KS $TMPDIR/kickstart/isolinux/ks/ks.cfg

# update the isolinux.cfg
sed -i 's/timeout 600/timeout 50/g' $TMPDIR/kickstart/isolinux/isolinux.cfg
sed -i '/menu default/d' $TMPDIR/kickstart/isolinux/isolinux.cfg
sed -i '/label linux/i label custom\n  menu label ^Install Custom CentOS 7\n  menu default\n  kernel vmlinuz\n  append initrd=initrd.img inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/ks/ks.cfg inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 quiet\n\n' $TMPDIR/kickstart/isolinux/isolinux.cfg

# generate the iso 
pushd $TMPDIR/kickstart
        mkisofs \
        -o ../$GENISO \
        -b isolinux.bin \
        -c boot.cat \
        -no-emul-boot \
        -V 'CentOS 7 x86_64' \
        -boot-load-size 4 \
        -boot-info-table -R -J -v \
        -T isolinux/
popd

# remove the temp and mnt directories
rm -rf $TMPDIR/kickstart
rm -rf $TMPDIR/mnt

# make it bootable from USB
isohybrid $TMPDIR/$GENISO