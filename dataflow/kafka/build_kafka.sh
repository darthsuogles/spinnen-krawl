#!/bin/bash

ver=1.0.0
tarball="kafka_2.11-${ver}.tgz"
[[ -f "${tarball}" ]] || \
    wget "http://mirror.reverse.net/pub/apache/kafka/${ver}/${tarball}"
tar -zxvf "${tarball}"
