#!/usr/bin/bash

#PRAGMA BLOAT

# Bloat courtesy of Mr. Daniel

# Spinner Author: Tasos Latsas
#
# Display an awesome 'spinner' while running your long shell commands
#
# Do *NOT* call _spinner function directly.
# Use {start,stop}_spinner wrapper functions

function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
    start)
        # calculate the column where spinner and status msg will be displayed
        let column="$(tput cols)-${#2}"-8
        # display message and position the cursor in $column column
        echo -ne "${2}"
        printf "%${column}s"

        # start spinner
        i=1
        sp='\|/-'
        delay=${SPINNER_DELAY:-0.15}

        while :; do
            printf "\b${sp:i++%${#sp}:1}"
            sleep "$delay"
        done
        ;;
    stop)
        if [[ -z ${3} ]]; then
            echo "spinner is not running.."
            exit 1
        fi

        kill "$3" >/dev/null 2>&1

        # inform the user uppon success or failure
        echo -en "\b["
        if [[ $2 -eq 0 ]]; then
            echo -en "$green$on_success$nc"
        else
            echo -en "$red$on_fail$nc"
        fi
        echo -e "]"
        ;;
    *)
        echo "invalid argument, try {start/stop}"
        exit 1
        ;;
    esac
}

function start_spinner {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" "$1" "$_sp_pid"
    unset _sp_pid
}

# end Bloat

# aux funcs
usage() {
    echo -e "Usage: \n\n$0 \n\
    [ -k ] Kills the qemu instance\n\
    [ -d ARCH_ARCH_DISK_IMG_PATH ]\n\
    [ -o LFS_ARCH_DISK_IMG_PATH ]\n\
    [ -s ARCH_DISKS_IMG_SIZE ]\n\
    [ -f LFS_DISKS_IMG_SIZE ]\n\
    [ -r RAM ]\n\
    [ -c CORES ]\n\
    [ -p ISO_PATH ]\n\
    [ -l <ssh | live> ]\n\
    [ -h ] Display this help message" \
        1>&2
    exit 1
}

command_exists() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "I require the command $1 but it's not installed. Abort."
        exit 1
    fi
}

file_exists() {
    # check if file exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if ! [[ -f $1 ]]; then
        echo "I require the file '$1' but it's wasn't found. Abort."
        exit 1
    fi
}

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
    [yY][eE][sS] | [yY])
        true
        ;;
    *)
        false
        ;;
    esac
}

kill_qemu() {
    # kill qemu if it's running
    if [[ -n $(pidof qemu-system-x86_64) ]]; then
        start_spinner "Killing qemu...  "
        sleep 1
        kill "$(pidof qemu-system-x86_64)"
        stop_spinner $?
    fi
}

# depts
for i in "qemu-img" "qemu-system-x86_64"; do
    command_exists "$i"
done

mkdir -p "$HOME/.config/lfs/"

# default values
ARCH_DISK_IMG_PATH="$HOME/.config/lfs/arch-linux-vm.raw"
LFS_DISK_IMG_PATH="$HOME/.config/lfs/lfs-vm.raw"
ARCH_DISK_IMG_SIZE="10G"
LFS_DISK_IMG_SIZE="20G"
ISO_PATH="https://geo.mirror.pkgbuild.com/iso/2022.06.01/archlinux-x86_64.iso"
RAM="4G"
CORES="$(($(nproc) / 2))"
BOOT_FROM="live"

while getopts :d:o:f:c:s:r:p:hl:k o; do
    case "$o" in
    d)
        ARCH_DISK_IMG_PATH=$OPTARG
        ;;
    o)
        LFS_DISK_IMG_PATH=$OPTARG
        ;;
    s)
        ARCH_DISK_IMG_SIZE=$OPTARG
        ;;
    f)
        LFS_DISK_IMG_SIZE=$OPTARG
        ;;
    r)
        RAM=$OPTARG
        ;;
    c)
        CORES=$OPTARG
        ;;
    p)
        ISO_PATH=$OPTARG
        ;;
    l)
        BOOT_FROM=$OPTARG
        ;;
    h)
        usage
        ;;
    k)
        kill_qemu
        exit 0
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

# if the arch disk image not exits, create one
if ! [ -f "$ARCH_DISK_IMG_PATH" ]; then
    start_spinner "Creating arch virtual disk image on: $ARCH_DISK_IMG_PATH"
    sleep 0.1
    qemu-img create -f raw "$ARCH_DISK_IMG_PATH" "$ARCH_DISK_IMG_SIZE" >/dev/null
    stop_spinner $?
else
    start_spinner "Using arch disk image: $ARCH_DISK_IMG_PATH"
    sleep 0.1
    stop_spinner $?
fi

# if the lfs disk image not exits, create one
if ! [ -f "$LFS_DISK_IMG_PATH" ]; then
    start_spinner "Creating lfs virtual disk image on: $LFS_DISK_IMG_PATH"
    sleep 0.1
    qemu-img create -f raw "$LFS_DISK_IMG_PATH" "$LFS_DISK_IMG_SIZE" >/dev/null
    stop_spinner $?
else
    start_spinner "Using lfs disk image: $LFS_DISK_IMG_PATH"
    sleep 0.1
    stop_spinner $?
fi

start_spinner "Running system. Wait to qemu to launch"
# sleep 0.1
case "$BOOT_FROM" in
ssh)
    qemu-system-x86_64 \
        --drive file="$ARCH_DISK_IMG_PATH",format=raw,media=disk \
        --drive file="$LFS_DISK_IMG_PATH",format=raw,media=disk --enable-kvm \
        -machine q35 \
        -device intel-iommu \
        -cpu host \
        -m "$RAM" \
        -nographic \
        -net nic \
        -net user,hostfwd=tcp:127.0.0.1:2222-:22 \
        -smp "$CORES",sockets=1,cores="$CORES" >/var/tmp/arch-linux-vm.log 2>&1 &
    ;;

live)
    qemu-system-x86_64 \
        --drive file="$ARCH_DISK_IMG_PATH",format=raw \
        --drive file="$LFS_DISK_IMG_PATH",format=raw \
        --enable-kvm \
        -machine q35 \
        -device intel-iommu \
        -cpu host \
        -m "$RAM" \
        -smp "$CORES",sockets=1,cores="$CORES" \
        -cdrom "$ISO_PATH" >/var/tmp/arch-linux-vm.log 2>&1 &
    ;;
*)
    stop_spinner $?
    usage
    ;;
esac
R="$?"
# wait for the VM to boot
sleep 10
stop_spinner "$R"

# If it was successfull and the VM is running, prompt the user that the ssh is already running and
# ask if he wants to connect to the VM
if [[ "$R" == "0" ]]; then
    # Clean the terminal
    clear
    printf "省 The VM ( ) is running.\n"
    confirm "Do you want to connect to the VM? [y/N] " && ssh arch@localhost -p 2222
fi
