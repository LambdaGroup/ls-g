#!/usr/bin/bash

mkdir -p "$HOME/.config/lfs/"

source "$(pwd)/utils/spinner.sh"

# aux funcs
usage() { echo "Usage: $0 [ -d DISK_IMG_PATH ] [-s DISKS_IMG_SIZE ] [ -r RAM ] [ -p ISO_PATH ] [ -l ]" 1>&2; exit 1; }

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

while getopts :d:s:r:p:hl o; do
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
            BOOT_FROM_RAW=0
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
if ! [ -f $DISK_IMG_PATH ]; then
  # echo "Creating virtual disk image"
  start_spinner "Creating virtual disk image"
  sleep 0.1
  qemu-img create -f raw $DISK_IMG_PATH $DISK_IMG_SIZE>/dev/null
  stop_spinner $?
else
  start_spinner "Virtual disk image found"
  sleep 0.1
  stop_spinner $?
fi

# run the vm
start_spinner "Using iso $ISO_PATH"
sleep 0.1
stop_spinner $?

start_spinner "Running system. Wait to qemu to launch"
sleep 0.1
if [ -z $BOOT_FROM_DISK ]; then
    qemu-system-x86_64 \
        --drive file=$DISK_IMG_PATH,format=raw \
        --enable-kvm \
        -machine q35 \
        -device intel-iommu \
        -cpu host \
        -m $RAM \
        -smp $(($(nproc) / 2)),sockets=1,cores=$(($(nproc) / 2)) 2>&1 >/var/tmp/arch-linux-vm.log &
else
    qemu-system-x86_64 \
        --drive file=$DISK_IMG_PATH,format=raw \
        --enable-kvm \
        -machine q35 \
        -device intel-iommu \
        -cpu host \
        -m $RAM \
        -smp $(($(nproc) / 2)),sockets=1,cores=$(($(nproc) / 2)) \
        -cdrom "$ISO_PATH" 2>&1 >/var/tmp/arch-linux-vm.log &
fi
stop_spinner $?
