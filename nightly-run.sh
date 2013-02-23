#!/bin/sh

# nightly run to update allowed_list and resync all repositories

ssh -i ~mirror-daemon/.ssh/id_rsa mirror-daemon@dev.freegeek.org ls /git > /git/allowed_list
for i in $(cat /git/allowed_list | grep -v ^distro$); do
    sudo su - www-data -c "/home/mirror-daemon/fg-git-tools/request-mirror-update git $i"
done
