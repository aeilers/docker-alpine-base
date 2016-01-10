# start with Alpine distro
FROM alpine:3.3

MAINTAINER Adam Eilers <adam.eilers@gmail.com>

# copy install scripts to image
COPY ./script/* /opt/script/

# add repositories, update, upgrade, and install bash and invoke environment install script
RUN printf "%s\n" \
        "http://dl-1.alpinelinux.org/alpine/v3.3/main" \
        "http://dl-1.alpinelinux.org/alpine/v3.3/community" \
        "http://dl-2.alpinelinux.org/alpine/v3.3/main" \
        "http://dl-2.alpinelinux.org/alpine/v3.3/community" \
        "http://dl-3.alpinelinux.org/alpine/v3.3/main" \
        "http://dl-3.alpinelinux.org/alpine/v3.3/community" \
        "http://dl-4.alpinelinux.org/alpine/v3.3/main" \
        "http://dl-4.alpinelinux.org/alpine/v3.3/community" \
        "http://dl-5.alpinelinux.org/alpine/v3.3/main" \
        "http://dl-5.alpinelinux.org/alpine/v3.3/community" \
    > /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk add bash-completion \
    && bash /opt/script/baseInstall.sh

# NOTE: onbuild task to create user for project-specific images
ONBUILD ARG USER_NAME
ONBUILD ARG USER_PASS
ONBUILD RUN bash /opt/script/userInstall.sh ${USER_NAME} ${USER_PASS}

# expose SSH port by default
EXPOSE 22
CMD ["/bin/bash"]
