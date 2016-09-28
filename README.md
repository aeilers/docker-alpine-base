# docker-alpine-base

Contains the Dockerfile and supporting install scripts for a Base [Alpine Linux](http://alpinelinux.org/) Docker image. (~15MB virtual size)

## Purpose

A few reasons:

- To provide a base set of tools in a more familiar shell,
- To provide additional script(s) for inheriting images,
- And to implement a single environment setup with minor variations for Development and Production images.

### Base set of tools

The tools provided are the [Bash shell w/ autocomplete](https://pkgs.alpinelinux.org/package/main/x86_64/bash-completion), full functionality for [common commands](https://pkgs.alpinelinux.org/package/main/x86_64/coreutils), fully functional [grep](https://pkgs.alpinelinux.org/package/main/x86_64/grep), and [recursive directory listing](https://pkgs.alpinelinux.org/package/main/x86_64/tree) capabilities. This is where most of the extra image size comes from with about ~10MB extra for all these features.

### Additional scripts

The user install script handles numerous tasks based on various settings passed in as [build-args](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg).

- If run by root and the `USER_NAME` and `USER_PASS` are passed in at build time, at minimum it will create the user and the home directory workspace.
- It checks if `IMAGE_TYPE` is "development" so it can add additional dev dependencies.
- Finally, it checks for `IMAGE_PROJECT` which is the https/ssh location of a [Git](https://pkgs.alpinelinux.org/package/main/x86_64/git) repository to go into `/home/${USER_NAME}/workspace`.

### Image variations

This is an attempt to, above all else, maintain consistency in environments from Development to Production. Alpine Linux starts ridiculously small at ~5MB. With the Base additions included in this image, it goes up to ~15MB. With their package manager, you simply start small and add what you need to achieve your final results. Sure Git adds a bit more to the Development image but consider CentOS7 starting at 194MB in comparison.

## Usage

This is a Base image, therefore not intended on being used directly. Child images need to specify the [FROM](https://docs.docker.com/engine/reference/builder/#from) keyword in their Dockerfile to point to this image.

```
FROM aeilers/alpine-base:2.0.0
```

Additionally, if you want to use the user install script in child/grandchild images, you will need to add the following [ONBUILD](https://docs.docker.com/engine/reference/builder/#onbuild) lines in the same Dockerfile.

```
ONBUILD ARG USER_NAME
ONBUILD ARG USER_PASS
ONBUILD ARG USER_SSH
ONBUILD ARG USER_SSH_PUB
ONBUILD ARG IMAGE_PROJECT
ONBUILD ARG IMAGE_TYPE="prod"
ONBUILD RUN bash /opt/script/userInstall.sh ${USER_NAME} ${USER_PASS}
```

## Change Log

-
