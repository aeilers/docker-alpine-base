#!/bin/bash

###
# environment install script for Alpine Linux on Docker
###

DIVIDER="===================="
TEMPLATE="\n\n${DIVIDER}${DIVIDER}${DIVIDER}\n%s\n\n\n"

printf "${TEMPLATE}" "Installing Alpine Linux Packages"

###
# NOTE: packages for env improvements are another personal preference here...
#   - bash-completion coreutils grep openssh tree
###
apk add \
    coreutils \
    grep \
    openssh \
    tree

# remove apk cache and list
printf "${TEMPLATE}" "Removing Alpine Linux Package Cache and /tmp"

rm -rf \
    /tmp/* \
    /var/cache/apk/*
