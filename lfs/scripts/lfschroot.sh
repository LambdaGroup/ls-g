#!/bin/bash

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='[\u@lfs \w]\$ '        \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login
