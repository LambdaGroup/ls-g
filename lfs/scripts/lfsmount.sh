#!/bin/bash

# lfs mount point
LFS=/mnt/lfs

# root device
LFS_ROOT=/dev/mmcblk0p2

# boot device
LFS_BOOT=/dev/mmcblk0p1

set -e

echo ' Mounting '$LFS'/ on '$LFS_ROOT
mount -v $LFS_ROOT $LFS

echo ' Mounting '$LFS'/boot on '$LFS_BOOT
mount -v $LFS_BOOT $LFS/boot

echo ' Bind /dev to '$LFS'/dev'
mount -v --bind /dev $LFS/dev

echo ' Bind /dev/pts to '$LFS'/dev/pts'
mount -v --bind /dev/pts $LFS/dev/pts

echo ' Mounting virtual file proc on '$LFS'/proc'
mount -vt proc proc $LFS/proc

echo ' Mounting virtual file sys on '$LFS'/sys'
mount -vt sysfs sysfs $LFS/sys

echo ' Mounting virtual file run on '$LFS'/run'
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
