load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

git_repository(
    name = "io_bazel_rules_pex",
    remote = "https://github.com/benley/bazel_rules_pex.git",
    tag = "0c5773db01ab8aeb3ae749b2fc570749b93af41f",
)

load("@io_bazel_rules_pex//pex:pex_rules.bzl", "pex_repositories")

pex_repositories()

rules_scala_version = "b537bddc58a77318b34165812a0311ef52806318"

http_archive(
    name = "io_bazel_rules_scala",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)

load("@io_bazel_rules_scala//scala:scala.bzl", "scala_repositories")

scala_repositories()

http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "6dede2c65ce86289969b907f343a1382d33c14fbce5e30dd17bb59bb55bb6593",
    strip_prefix = "rules_docker-0.4.0",
    urls = ["https://github.com/bazelbuild/rules_docker/archive/v0.4.0.tar.gz"],
)

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
    container_repositories = "repositories",
)

container_repositories()

container_pull(
    name = "java_base",
    registry = "gcr.io",
    repository = "distroless/java",
    # 'tag' is also supported, but digest is encouraged for reproducibility.
    tag = "latest",
)

container_pull(
    name = "official_ubuntu",
    registry = "index.docker.io",
    repository = "library/ubuntu",
    tag = "16.04",
)

maven_jar(
    name = "google_guava",
    artifact = "com.google.guava:guava:18.0",
)

maven_jar(
    name = "beust_jcommander",
    artifact = "com.beust:jcommander:1.72",
)

## Bazel rule file

# buildifier is written in Go and hence needs rules_go to be built.
# See https://github.com/bazelbuild/rules_go for the up to date setup instructions.
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "c1f52b8789218bb1542ed362c4f7de7052abcf254d865d96fb7ba6d44bc15ee3",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.12.0/rules_go-0.12.0.tar.gz",
)

bazel_buildtools_version = "a90c3a9f00e27973d3e759d17f2e2e7d9702d91b"

http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-{}".format(bazel_buildtools_version),
    url = "https://github.com/bazelbuild/buildtools/archive/{}.zip".format(bazel_buildtools_version),
)

load("@io_bazel_rules_go//go:def.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@com_github_bazelbuild_buildtools//buildifier:deps.bzl", "buildifier_dependencies")

go_rules_dependencies()

go_register_toolchains()

buildifier_dependencies()

# gflags
# https://gflags.github.io/gflags/#bazel
git_repository(
    name = "com_github_gflags_gflags",
    remote = "https://github.com/gflags/gflags.git",
    commit = "e171aa2d15ed9eb17054558e0b3a6a413bb01067",
)

# boost
# https://github.com/nelhage/rules_boost
git_repository(
    name = "com_github_nelhage_rules_boost",
    commit = "8a8853fd755496288995a603ce9aa2685709cd39",
    remote = "https://github.com/nelhage/rules_boost",
)

load("@com_github_nelhage_rules_boost//:boost/boost.bzl", "boost_deps")
boost_deps()

# Protocol buffer
git_repository(
    name = "org_pubref_rules_protobuf",
    commit = "5cae42382b620aa1e347ecf30b3e92fd0d97998c",
    remote = "https://github.com/pubref/rules_protobuf",
)

load("@org_pubref_rules_protobuf//python:rules.bzl", "py_proto_repositories")

py_proto_repositories()

# Ignore some directories
local_repository(
    name = "ignored_tensorflow_examples",
    path = "./dlsys/tnsrphlw_ex",
)

local_repository(
    name = "ignored_spark",
    path = "./spark",
)

# Simply providing some directories as external files
local_repository(
    name = "natlang_sling",
    path = "./natlang/sling",
)

local_repository(
    name = "dlsys_custom_tensorflow_ops",
    path = "./dlsys/custom_tensorflow_ops",
)

local_repository(
    name = "golang_bazel_buildtools",
    path = "./lang/go/src/github.com/bazelbuild/buildtools",
)

local_repository(
    name = "tensorflow_serving",
    path = "./third_party/serving",
)

local_repository(
    name = "bazel_custom_toolchain",
    path = "./infra/crossbuild/custom_toolchain",
)

new_local_repository(
    name = "tensorflow_models",
    build_file = "./third_party/BUILD.tensorflow_models",
    path = "./third_party/tensorflow_models/research",
)

# Foreign rules
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Group the sources of the library so that CMake rule have access to it
all_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])"""

# Rule repository
http_archive(
   name = "rules_foreign_cc",
   strip_prefix = "rules_foreign_cc-master",
   url = "https://github.com/bazelbuild/rules_foreign_cc/archive/master.zip",
)

load("@rules_foreign_cc//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

# Workspace initialization function; includes repositories needed by rules_foreign_cc,
# and creates some utilities for the host operating system
rules_foreign_cc_dependencies()

# OpenBLAS source code repository
http_archive(
   name = "openblas",
   build_file_content = all_content,
   strip_prefix = "OpenBLAS-0.3.2",
   urls = ["https://github.com/xianyi/OpenBLAS/archive/v0.3.2.tar.gz"],
)

# Eigen source code repository
http_archive(
   name = "eigen",
   build_file_content = all_content,
   strip_prefix = "eigen-git-mirror-3.3.5",
   urls = ["https://github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz"],
)

new_local_repository(
    name = "point_cloud_library",
    path = "/usr/local/opt/pcl",
    build_file = "./third_party/BUILD.pcl",
)

new_local_repository(
    name = "eigen",
    path = "/usr/local/opt/eigen",
    build_file = "./third_party/BUILD.eigen",
)
