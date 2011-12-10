#!/bin/sh

# nightly run to update allowed_list and resync all repositories

ssh -i ~/.ssh/scp_key dev.freegeek.org ls /git > /git/allowed_list
for i in $(cat /git/allowed_list); do
    sudo su - www-data -c "/home/ryan52/request-mirror-update git $i"
done