#!/bin/bash

mkdir -p "$HOME/.config/lfs/"

LFS_CONFIG_FILE="$HOME/.config/lfs/.lfs_config"

DIALOG_CANCEL=1
DIALOG_ESC=255

check_dialog () {
    case $? in
        "$DIALOG_CANCEL")
            echo "Canceled..." && exit
        ;;
        "$DIALOG_ESC")
            echo "Canceled..." && exit
        ;;
    esac
}

command_exists() {
    # check if command exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if [[ $? -ne 0  ]]; then
        echo "I require the command $1 but it's not installed. Abort."
        exit 1
    fi
}

read_config () {
    DEVS=($(tail -n +2 <(lsblk -plo NAME)))

    CMD=(dialog --keep-tite --backtitle "LFS mount" --title "LFS directory" --inputbox "" 6 80 "/mnt/lfs")
    LFS=$("${CMD[@]}" 2>&1 >/dev/tty)

    check_dialog
    if ! [[ -d $LFS ]]; then
        echo "$LFS does not exist..."
        exit 1
    fi

    CMD=(dialog --keep-tite --title "LFS root mount point" --menu "" 40 80 16)
    OPT=($(for i in "${!DEVS[@]}"; do echo "$i ${DEVS[$i]}"; done))
    LFS_ROOT=$("${CMD[@]}" "${OPT[@]}" 2>&1 >/dev/tty)
    check_dialog

    CMD=(dialog --keep-tite --title "LFS boot mount point" --menu "" 40 80 16)
    OPT=($(for i in "${!DEVS[@]}"; do [ "$LFS_ROOT" != "$i" ] && echo "$i ${DEVS[$i]}"; done))
    LFS_BOOT=$("${CMD[@]}" "${OPT[@]}" 2>&1 >/dev/tty)
    check_dialog
}

save_config () {
    echo "Saving to $LFS_CONFIG_FILE"
    LFS_ROOT=${DEVS[$LFS_ROOT]}
    LFS_BOOT=${DEVS[$LFS_BOOT]}
    echo -e "LFS=$LFS\nLFS_ROOT=$LFS_ROOT\nLFS_BOOT=$LFS_BOOT" > $LFS_CONFIG_FILE
}

do_chroot () {
    echo 'chroot into LFS'
    [[ -z $RET ]] && bash lfschroot.sh
}

check_mountpoint(){
    if  mountpoint -q "$1"
    then
        echo "$1"' is mounted'
        # NOTE: don't use the return value, using set -e
        MOUNTED=0
    else
        MOUNTED=1
    fi
}

command_exists "dialog"

if [ -f $LFS_CONFIG_FILE ]; then
    echo "Loading config from $LFS_CONFIG_FILE"
    source $LFS_CONFIG_FILE
else
    read_config
    save_config
fi

CMD=(dialog --keep-tite --title "Config done!" --yesno "chroot into LFS?" 20 30)
RET=$("${CMD[@]}" 2>&1 >/dev/tty)

set -e

check_mountpoint "$LFS"
if [ $MOUNTED -gt "0" ]; then
    echo 'Mounting '"$LFS"'/ on '"$LFS_ROOT"
    mount "$LFS_ROOT" "$LFS"
fi

check_mountpoint "$LFS"/boot
if [ $MOUNTED -gt "0" ]; then
    echo 'Mounting '"$LFS"'/boot on '"$LFS_BOOT"
    mount "$LFS_BOOT" "$LFS"/boot
fi

check_mountpoint "$LFS"/dev
if [ $MOUNTED -gt "0" ]; then
    echo 'Bind /dev to '"$LFS"'/dev'
    mount --bind /dev "$LFS"/dev
fi

check_mountpoint "$LFS"/dev/pts
if [ $MOUNTED -gt "0" ]; then
    echo 'Bind /dev/pts to '"$LFS"'/dev/pts'
    mount --bind /dev/pts "$LFS"/dev/pts
fi

check_mountpoint "$LFS"/proc
if [ $MOUNTED -gt "0" ]; then
    echo 'Mounting virtual file proc on '"$LFS"'/proc'
    mount -t proc proc "$LFS"/proc
fi

check_mountpoint "$LFS"/sys
if [ $MOUNTED -gt "0" ]; then
    echo 'Mounting virtual file sys on '"$LFS"'/sys'
    mount -t sysfs sysfs "$LFS"/sys
fi

check_mountpoint "$LFS"/run
if [ $MOUNTED -gt "0" ]; then
    echo 'Mounting virtual file run on '"$LFS"'/run'
    mount -t tmpfs tmpfs "$LFS"/run
fi

if [ -h "$LFS"/dev/shm ]; then
    mkdir -p "$LFS"/"$(readlink "$LFS"/dev/shm)"
fi

do_chroot
