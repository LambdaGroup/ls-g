#!/usr/bin/bash

mkdir -p "$HOME/.config/lfs/"

source "$(pwd)/utils/spinner.sh"

# aux funcs
usage() { echo "Usage: $0 [ -d DISK_IMG_PATH ] [-s DISKS_IMG_SIZE ] [ -r RAM ] [ -p ISO_PATH ] [ -l <ssh | live> ]" 1>&2; exit 1; }

command_exists() {
    # check if command exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if [[ $? -ne 0  ]]; then
        echo "I require the command $1 but it's not installed. Abort."
        exit 1
    fi
}

file_exists() {
    # check if file exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if ! [[ -f $1  ]]; then
        echo "I require the file '$1' but it's wasn't found. Abort."
        exit 1
    fi
}

# depts
for i in "qemu-img" "qemu-system-x86_64" ; do
    command_exists ${i}
done

# default values
DISK_IMG_PATH="$HOME/.config/lfs/arch-linux-vm.raw"
DISK_IMG_SIZE="30G"
ISO_PATH="https://geo.mirror.pkgbuild.com/iso/2022.06.01/archlinux-x86_64.iso"
RAM="4G"

while getopts :d:s:r:p:hl: o; do
    case "${o}" in
        d)
            DISK_IMG_PATH=${OPTARG}
            ;;
        s)
            DISK_IMG_SIZE=${OPTARG}
            ;;
        r)
            RAM=${OPTARG}
            ;;
        p)
            ISO_PATH=${OPTARG}
            ;;
        h)
            usage
            ;;
        l)
            BOOT_FROM=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

start_spinner "Using disk image: $DISK_IMG_PATH"
sleep 0.1
stop_spinner $?

# if the disk image not exits, create one
if ! [ -f "$DISK_IMG_PATH" ]; then
  # echo "Creating virtual disk image"
  start_spinner "Creating virtual disk image"
  sleep 0.1
  qemu-img create -f raw "$DISK_IMG_PATH" "$DISK_IMG_SIZE">/dev/null
  stop_spinner $?
else
  start_spinner "Virtual disk image found"
  sleep 0.1
  stop_spinner $?
fi

PROCS="$(($(nproc) / 2))"

start_spinner "Running system. Wait to qemu to launch"
sleep 0.1
case "$BOOT_FROM" in
    ssh )
        qemu-system-x86_64 \
            --drive file="$DISK_IMG_PATH",format=raw \
            --enable-kvm \
            -machine q35 \
            -device intel-iommu \
            -cpu host \
            -m "$RAM" \
            -nographic \
            -net nic \
            -net user,hostfwd=tcp:127.0.0.1:2222-:22 \
            -smp "$PROCS",sockets=1,cores="$PROCS" >/var/tmp/arch-linux-vm.log 2>&1 & \
            ;;

    live )
        qemu-system-x86_64 \
            --drive file="$DISK_IMG_PATH",format=raw \
            --enable-kvm \
            -machine q35 \
            -device intel-iommu \
            -cpu host \
            -m "$RAM" \
            -smp "$PROCS",sockets=1,cores="$PROCS" \
            -cdrom "$ISO_PATH" >/var/tmp/arch-linux-vm.log 2>&1  & \
            ;;
    * )
        usage
esac
stop_spinner $?
