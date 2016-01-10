#!/bin/bash

###
# user install script for Alpine Linux on Docker
###

if [[ "${EUID}" == "0" && $1 && $2 ]]
then

    DIVIDER="===================="
    TEMPLATE="\n\n${DIVIDER}${DIVIDER}${DIVIDER}\n%s\n\n\n"

    HOME_DIR="/home/$1"
    WORK_DIR="workspace"

    printf "${TEMPLATE}" "Creating User Account"

    adduser -s /bin/bash -D -G wheel -S $1
    printf "$1:`echo -n $2 | sha256sum`" | chpasswd -e

    chown -R $1:root /opt

    mkdir -p ${HOME_DIR}/${WORK_DIR}

    if [[ ${IMAGE_TYPE} == "dev" ]]
    then

        printf "${TEMPLATE}" "Installing Alpine Linux Packages"

        apk update && apk add \
            samba \
            samba-common-tools

        printf "%s\n" \
            "[global]" \
            "security = user" \
            "encrypt passwords = yes" \
            "unix password sync = yes" \
            "" \
            "[${WORK_DIR}]" \
            "path = ${HOME_DIR}/${WORK_DIR}" \
            "available = yes" \
            "valid users = $1" \
            "read only = no" \
            "browsable = yes" \
            "public = yes" \
            "writable = yes" \
        >> /etc/samba/smb.conf

        (echo "$2"; echo "$2") | smbpasswd -s -a $1

    fi

    if [[ ${IMAGE_PROJECT} ]]
    then

        printf "${TEMPLATE}" "Installing Alpine Linux Packages"

        apk update && apk add git

        # setup credential memory cache
        git config --global credential.helper cache

        # increase cache timeout from default to 4 hours
        git config --global credential.helper 'cache --timeout=28800'

        printf "${TEMPLATE}" "Getting Project"

        (echo "$1"; echo "$2") | git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}

        if [[ "${IMAGE_TYPE}" == "prod" ]]
        then
            apk del git

            rm -rf \
                ${HOME_DIR}/${WORK_DIR}/.git \
                ${HOME_DIR}/${WORK_DIR}/*.md
        fi

    fi

fi

# remove apk cache and list
printf "${TEMPLATE}" "Removing Alpine Linux Package Cache and /tmp"

rm -rf \
    /tmp/* \
    /var/cache/apk/*
