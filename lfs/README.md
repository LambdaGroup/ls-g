# This folder contains all the thing we will need to go thought LFS!

## [Linux From Scratch](https://linuxfromscratch.org/lfs/view/development/chapter01/how.html)

We will start Linux From Scratch following the link above, use the script `./lfsqemu.sh -l ssh` to run the virtual machine and connect with `ssh`. **Make sure to run the commands on the virtual machine as it can cause damage to the host (your computer)**.

## [Scritps](scripts)

- The [`lfsqemu.sh`](scripts/lfsqemu.sh) will start an Arch Linux virtual machine (we recommend using it as it prevents accidental damage to the host system);
- The [`lfsmount.sh`](scripts/lfsmount.sh) will mount the devices and ask if you would like to `chroot` into the LFS (this **MUST** be ran as the root user, **DO NOT** use `sudo`);
- The [`lfschroot.sh`](scripts/lfschroot.sh) will `chroot` into the LFS environment (we recommend using `lfsmount.sh` instead).
