#!/bin/bash

set -eux -o pipefail

export GOPATH=$HOME/CodeBase/spinnen-krawl/golang
export PATH=$GOPATH/bin:$PATH

mkdir -p $GOPATH/bin

go get github.com/jteeuwen/go-bindata
pushd $GOPATH/src/github.com/jteeuwen/go-bindata/go-bindata
go build
cp -f go-bindata $GOPATH/bin/.
popd

mkdir -p $GOPATH/src/github.com/aliyun
pushd $GOPATH/src/github.com/aliyun

[[ -d aliyun-cli ]] || \
    git clone http://github.com/aliyun/aliyun-cli.git
[[ -d aliyun-openapi-meta ]] || \
    git clone http://github.com/aliyun/aliyun-openapi-meta.git

pushd aliyun-cli; go get ./...; make install; popd
popd
