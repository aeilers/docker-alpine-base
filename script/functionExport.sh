#!/bin/bash

clearApkCache () {
    rm -rf \
        /tmp/* \
        /var/cache/apk/*
}

###
# exports
###
export -f clearApkCache
