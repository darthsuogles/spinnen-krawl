#!/bin/bash

set -euo pipefail

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

spark_ver=2.3.0
spark_tarball="spark-${spark_ver}-bin-hadoop2.7.tgz"
spark_dir="${spark_tarball%.*}"

apache_mirror_cgi="https://www.apache.org/dyn/closer.lua"
spark_rel_path="spark/spark-${spark_ver}/${spark_tarball}"
spark_url="${apache_mirror_cgi}?path=${spark_rel_path}"

function spark_home {
    local _spark_home="${_bsd_}/prebuilt/${spark_dir}"
    echo "export SPARK_HOME=${_spark_home}"
cat << _PYSPARK_EOF_ > .ipy3
#!/bin/bash

set -euo pipefail

export SPARK_HOME="${_spark_home}"
export PYSPARK_DRIVER_PYTHON=ipython3
export PYSPARK_DRIVER_PYTHON_OPTS="-i --simple-prompt"
export PYSPARK_PYTHON=python3

(cd ${_bsd_}; exec \${SPARK_HOME}/bin/pyspark $@)

_PYSPARK_EOF_

chmod +x .ipy3
}

if [[ -d "${_bsd_}/prebuilt/${spark_dir}" ]]; then
    echo >&2 "Spark ${spark_ver} have already been downloaded"
    spark_home
    exit 0
fi

pushd "${_bsd_}"

python -- << __PY_SCRIPT_EOF__ | xargs wget
import sys, json
json_str = """$(curl --silent --location "${spark_url}&asjson=1")"""
pkg_info = json.loads(json_str)
print("{}/${spark_rel_path}".format(pkg_info["preferred"]))
__PY_SCRIPT_EOF__

(mkdir -p prebuilt && cd $_
 [[ -d "${spark_tarball%.*}" ]] || (
     mv "../${spark_tarball}" .
     tar -zxvf "${spark_tarball}"
 )
)
popd

spark_home
