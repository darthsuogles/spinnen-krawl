#!/bin/bash

set -eux -o pipefail

#####
# 2. Prepare Client Tools
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md

# Contains both cfssl and cfssljson
brew install cfssl
cfssl version

function try_fetch_kubectl {
    k8s_stable_version="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
    cat <<_INFO_EOF_
    Downloading kubectl ${k8s_stable_version} from instructions provided at
    https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl
_INFO_EOF_
    curl --retry 3 -LO \
         "https://storage.googleapis.com/kubernetes-release/release/${k8s_stable_version}/bin/darwin/amd64/kubectl"
    chmod +x kubectl
}

[[ -x ./kubectl ]] || try_fetch_kubectl
./kubectl version --client

#####
# 3. Provisioning Compute Resources
# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md
