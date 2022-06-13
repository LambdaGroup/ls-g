#!/usr/bin/env bash

source "$(pwd)/utils/spinner.sh"

# aux funcs
usage() { echo "Usage: $0 [ -d DISK_IMG_PATH ] [-s DISKS_IMG_SIZE ] [ -r RAM ] [ -p ISO_PATH ]" 1>&2; exit 1; }

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
DISK_IMG_PATH="arch_vm.raw"
DISK_IMG_SIZE="30G"
ISO_PATH="https://geo.mirror.pkgbuild.com/iso/2022.06.01/archlinux-x86_64.iso"
RAM="512M"

while getopts :d:s:r:p:h o; do
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
        *)
          usage
          ;;
    esac
done
shift $((OPTIND-1))

start_spinner "Using disk image: $DISK_IMG_PATH"
sleep 1
stop_spinner $?

# if the disk image not exits, create one
if ! [ -f $DISK_IMG_PATH ]; then
  # echo "Creating virtual disk image"
  start_spinner "Creating virtual disk image"
  sleep 1
  qemu-img create -f raw $DISK_IMG_PATH $DISK_IMG_SIZE >log/qemu-img.log
  stop_spinner $?
else
  start_spinner "Virtual disk image found"
  sleep 1
  stop_spinner $?
fi


# run the vm
# spinner $$ &
start_spinner "Running system. Wait to qemu to launch"
sleep 1
qemu-system-x86_64 \
    --drive file="$DISK_IMG_PATH",format=raw\
    --enable-kvm\
    -machine q35\
    -device intel-iommu\
    -cpu host\
    -boot order=dc,menu=on\
    -m $RAM\
    -cdrom "$ISO_PATH" &
stop_spinner $?
