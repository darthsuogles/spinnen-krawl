#!/bin/bash

set -euo pipefail

TMP_SCRIPT="/tmp/conda_install.sh"

wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O "${TMP_SCRIPT}"
bash "${TMP_SCRIPT}" -b -p "${HOME}/miniconda"
export PATH="${HOME}/miniconda/bin:$PATH"

rm -f "${TMP_SCRIPT}"
