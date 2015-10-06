#!/bin/bash
# Vlata Mikes - remote skript pro check kvm

case $1 in
    list) virsh list --all;;
    dumpxml) virsh dumpxml $2;;
    *) echo invalid option;exit 1;;
esac