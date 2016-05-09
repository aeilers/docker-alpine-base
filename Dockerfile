# start with Alpine distro
FROM alpine:3.3

MAINTAINER Adam Eilers <adam.eilers@gmail.com>

# copy install scripts to image
COPY ./script/*Export.sh /etc/profile.d/
COPY ./script/*Install.sh /opt/script/

# add repositories, update, upgrade, install bash, and invoke base install script
RUN apk update && apk upgrade \
    && apk add bash-completion \
    && bash /opt/script/baseInstall.sh

# NOTE: onbuild task to create user for project-specific images
ONBUILD ARG USER_NAME
ONBUILD ARG USER_PASS
ONBUILD ARG USER_SSH
ONBUILD ARG USER_SSH_PUB
ONBUILD ARG IMAGE_PROJECT
ONBUILD ARG IMAGE_TYPE="production"
ONBUILD RUN bash /opt/script/userInstall.sh "${USER_NAME}" "${USER_PASS}" "${USER_SSH}" "${USER_SSH_PUB}"

CMD ["/bin/bash"]
