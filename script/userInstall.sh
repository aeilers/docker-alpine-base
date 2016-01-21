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

    adduser -D -G wheel -s /bin/bash -S $1
    printf "$1:$(printf "$2" | sha256sum)" | chpasswd -e

    mkdir -p ${HOME_DIR}/${WORK_DIR}

    chown -R $1:wheel /opt
    chown -R $1:wheel ${HOME_DIR}/${WORK_DIR}

    apk update

    # setup git if image project is passed
    if [[ ${IMAGE_PROJECT} ]]
    then

        printf "${TEMPLATE}" "Installing Alpine Linux Packages for Git"

        apk add \
            git \
            sudo

        # check if SSH key is passed
        if [[ $3 && $4 ]]
        then

            # install ssh client
            apk add openssh-client

            PREFIX="-----BEGIN RSA PRIVATE KEY-----"
            SUFFIX="-----END RSA PRIVATE KEY-----"

            printf "${TEMPLATE}" "Storing SSH Key"

            mkdir -p ${HOME_DIR}/.ssh

            # parse private key
            TEMP="$3"
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
            printf "${TEMPLATE}" "Getting Project"

            sudo -u ${USER_NAME} git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}

        else

            # setup credential memory cache
            git config --global credential.helper cache

            # increase cache timeout from default to 8 hours
            git config --global credential.helper 'cache --timeout=28800'

            # checkout code using HTTPS as the user here
            printf "${TEMPLATE}" "Getting Project"

            (printf "${USER_NAME}"; printf "${USER_PASS}") | sudo -u ${USER_NAME} git clone ${IMAGE_PROJECT} ${HOME_DIR}/${WORK_DIR}

        fi

        # clean-up for prod deployment
        if [[ "${IMAGE_TYPE}" == "prod" ]]
        then

            apk del \
                git \
                openssh-client \
                sudo

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
