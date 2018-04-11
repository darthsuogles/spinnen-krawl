#!/bin/bash

echo "Install xhyve driver"
brew install docker-machine-driver-xhyve

function quit_with { >&2 echo "ERROR: $@, quit"; exit 1; }

function sudo_inst {
    local _prefix=$(brew --prefix docker-machine-driver-xhyve)
    echo "Run the following commands since xhyve requires sudo access"
    cat <<_XHYVE_EOF_
       sudo chown root:wheel ${_prefix}/bin/docker-machine-driver-xhyve
       sudo chmod u+s ${_prefix}/bin/docker-machine-driver-xhyve
_XHYVE_EOF_
}

function check_vbox_bins {
    local _vbox_bins="$(find /usr/local/bin/ -name 'vbox*' -o -name 'VBox*')"
    if [[ -n "${_vbox_bins}" ]]; then
        quit_with "Please remove ${_vbox_bins}"
    fi    
}

sudo_inst
check_vbox_bins

[[ -x /usr/local/bin/minikube ]] || (
    curl -Lo minikube \
         https://storage.googleapis.com/minikube/releases/v0.18.0/minikube-darwin-amd64 \
        && chmod +x minikube && sudo mv minikube /usr/local/bin/
)

[[ -x /usr/local/bin/kubectl ]] || (
    curl -Lo kubectl \
         https://storage.googleapis.com/kubernetes-release/release/v1.6.0/bin/darwin/amd64/kubectl \
        && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
)

echo "Initialize minikube"
echo "       minikube start --vm-driver=xhyve"
