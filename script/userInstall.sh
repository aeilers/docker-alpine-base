#!/bin/bash

###
# user install script for Alpine Linux on Docker
# $1 - user name
# $2 - user password
# $3 - user private ssh key
# $4 - user public ssh key
###
runUser () {
    local DIVIDER="===================="
    local TEMPLATE="\n\n${DIVIDER}${DIVIDER}${DIVIDER}\n%s\n\n\n"

    if [[ "${EUID}" == "0" && $1 && $2 ]]
    then
        printf "${TEMPLATE}" "Creating User Account"
        setupUser $1 $2

        # setup git if image project is passed
        if [[ ${IMAGE_PROJECT} ]]
        then
            printf "${TEMPLATE}" "Installing Alpine Linux Packages for Git"
            setupGit $1

            if [[ $3 && $4 ]]
            then
                printf "${TEMPLATE}" "Setup SSH Project"
                setupSshProject $1 $2 $3 $4
            else
                printf "${TEMPLATE}" "Setup User Project"
                setupUserProject $1 $2
            fi

            # clean-up for prod deployment
            if [[ "${IMAGE_TYPE}" == "production" ]]
            then
                printf "${TEMPLATE}" "Clear User Install Cache"
                clearUserInstallCache
            fi
        fi
    else
        printf "${TEMPLATE}" "User must be root and username password must be supplied."
    fi

    # remove apk cache and list
    printf "${TEMPLATE}" "Removing Alpine Linux Package Cache and /tmp"
    clearApkCache
}

###
# setup functions for user and project variants
###
setupUser () {
    export HOME_DIR="/home/$1"
    export WORK_DIR="workspace"

    adduser -D -G wheel -s /bin/bash -S $1
    printf "$1:$(printf "$2" | sha256sum)" | chpasswd -e

    mkdir -p ${HOME_DIR}/${WORK_DIR}

    chown -R $1:wheel /opt
    chown -R $1:wheel ${HOME_DIR}/${WORK_DIR}

    apk update
}

setupSshProject () {
    # install ssh client
    apk add openssh-client

    local PREFIX="-----BEGIN RSA PRIVATE KEY-----"
    local SUFFIX="-----END RSA PRIVATE KEY-----"

    mkdir -p ${HOME_DIR}/.ssh

    # parse private key
    local TEMP="$3"
    TEMP=${TEMP/#${PREFIX}/}
    TEMP=${TEMP/%${SUFFIX}/}
    TEMP="$(tr " " "\n" <<< ${TEMP})"

    # create private and public keys
    printf "%s\n" "${PREFIX}" "${TEMP}" "${SUFFIX}" > ${HOME_DIR}/.ssh/id_rsa
    printf "$4" > ${HOME_DIR}/.ssh/id_rsa.pub

    # get host info from project and add it to known_hosts
    if [[ ${IMAGE_PROJECT} =~ @([\-A-Za-z0-9.]+): ]]
    then
        ssh-keyscan -H "${BASH_REMATCH[1]}" >> ${HOME_DIR}/.ssh/known_hosts
    fi

    chown -R $1:wheel ${HOME_DIR}/.ssh

    chmod 600 ${HOME_DIR}/.ssh/id_rsa
    chmod 644 ${HOME_DIR}/.ssh/id_rsa.pub
    chmod 644 ${HOME_DIR}/.ssh/known_hosts

    # checkout code using SSH as the user here
    sudo -u $1 git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}
}

setupUserProject () {
    # setup credential memory cache
    git config --global credential.helper cache

    # increase cache timeout from default to 8 hours
    git config --global credential.helper 'cache --timeout=28800'

    # checkout code using HTTPS as the user here
    (printf "$1"; printf "$2") | sudo -u $1 git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}
}

###
# helper functions
###
clearUserInstallCache () {
    apk del \
        git \
        openssh-client \
        sudo

    rm -rf \
        ${HOME_DIR}/${WORK_DIR}/.git \
        ${HOME_DIR}/${WORK_DIR}/*.md
}

setupGit () {
    apk add \
        git \
        sudo

    git config --global user.name "$1"
}

###
# main
###
source /etc/profile

if [[ $1 && $2 ]]
then
    runUser $1 $2 $3 $4
fi
