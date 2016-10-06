#!/bin/bash

###
# user install script for Alpine Linux on Docker
# ${USER_NAME} - user name
# ${USER_PASS} - user password
# ${USER_SSH} - user private ssh key
# ${USER_SSH_PUB} - user public ssh key
###
runUser () {
    local DIVIDER="===================="
    local TEMPLATE="\n\n${DIVIDER}${DIVIDER}${DIVIDER}\n%s\n\n\n"

    if [[ "${EUID}" == "0" ]]
    then
        printf "${TEMPLATE}" "Creating User Account"
        setupUser

        printf "${TEMPLATE}" "Installing Alpine Linux Packages for Environment"
        setupEnvironment

        # setup git if image project is passed
        if [[ ${IMAGE_PROJECT} ]]
        then
            if [[ ${USER_SSH} && ${USER_SSH_PUB} ]]
            then
                printf "${TEMPLATE}" "Setup SSH Project"
                setupSshProject
            else
                printf "${TEMPLATE}" "Setup User Project"
                setupUserProject
            fi
        fi

        # clean-up for prod deployment
        if [[ "${IMAGE_TYPE}" == "production" ]]
        then
            printf "${TEMPLATE}" "Clear User Install Cache"
            clearUserInstallCache
        fi
    else
        printf "${TEMPLATE}" "User must be root to run this script."
    fi

    # remove apk cache and list
    printf "${TEMPLATE}" "Removing Alpine Linux Package Cache and /tmp"
    clearApkCache
}

###
# setup basic user
# ${USER_NAME} - user name
# ${USER_PASS} - user password
###
setupUser () {
    export HOME_DIR="/home/${USER_NAME}"
    export WORK_DIR="workspace"

    adduser -D -G wheel -s /bin/bash -S ${USER_NAME}
    printf "${USER_NAME}:$(printf "${USER_PASS}" | sha256sum)" | chpasswd -e

    mkdir -p ${HOME_DIR}/${WORK_DIR}

    chown -R ${USER_NAME}:wheel /opt
    chown -R ${USER_NAME}:wheel ${HOME_DIR}/${WORK_DIR}

    apk update
}

###
# setup user ssh project
# ${USER_NAME} - user name
# ${USER_SSH} - user private ssh key
# ${USER_SSH_PUB} - user public ssh key
###
setupSshProject () {
    local PREFIX="-----BEGIN RSA PRIVATE KEY-----"
    local SUFFIX="-----END RSA PRIVATE KEY-----"

    mkdir -p ${HOME_DIR}/.ssh

    # parse private key
    local TEMP="${USER_SSH}"
    TEMP=${TEMP/#${PREFIX}/}
    TEMP=${TEMP/%${SUFFIX}/}
    TEMP="$(tr " " "\n" <<< ${TEMP})"

    # create private and public keys
    printf "%s\n" "${PREFIX}" "${TEMP}" "${SUFFIX}" > ${HOME_DIR}/.ssh/id_rsa
    printf "${USER_SSH_PUB}" > ${HOME_DIR}/.ssh/id_rsa.pub

    # get host info from project and add it to known_hosts
    if [[ ${IMAGE_PROJECT} =~ @([\-A-Za-z0-9.]+): ]]
    then
        ssh-keyscan -H "${BASH_REMATCH[1]}" >> ${HOME_DIR}/.ssh/known_hosts
    fi

    chown -R ${USER_NAME}:wheel ${HOME_DIR}/.ssh

    chmod 600 ${HOME_DIR}/.ssh/id_rsa
    chmod 644 ${HOME_DIR}/.ssh/id_rsa.pub
    chmod 644 ${HOME_DIR}/.ssh/known_hosts

    # checkout code using SSH as the user here
    sudo -u ${USER_NAME} git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}
}

###
# setup user https project
# ${USER_NAME} - user name
# ${USER_PASS} - user password
###
setupUserProject () {
    # setup credential memory cache
    git config --global credential.helper cache

    # increase cache timeout from default to 8 hours
    git config --global credential.helper 'cache --timeout=28800'

    # checkout code using HTTPS as the user here
    (printf "${USER_NAME}"; printf "${USER_PASS}") | sudo -u ${USER_NAME} git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}
}

###
# clear cache
###
clearUserInstallCache () {
    apk del \
        docker \
        docker-bash-completion \
        git \
        openssh-client \
        sudo

    rm -rf \
        ${HOME_DIR}/${WORK_DIR}/.git \
        ${HOME_DIR}/${WORK_DIR}/*.md
}

###
# setup user git config
# ${USER_NAME} - user name
###
setupEnvironment () {
    apk add \
        docker \
        docker-bash-completion \
        git \
        openssh-client \
        sudo

    git config --global user.name "${USER_NAME}"
}

###
# main
###
if [[ ${USER_NAME} && ${USER_PASS} ]]
then
    source /etc/profile && runUser
fi
