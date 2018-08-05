#!/bin/bash

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -euxo pipefail

topic="local_system_log"
log_dir="${PWD}"

pushd "${_bsd_}/kafka_2.11-1.0.0"

echo "Initialize ZooKeeper"
bin/zookeeper-server-start.sh config/zookeeper.properties &> "${log_dir}/zkpr.log" &

echo "Initialize Kafka"
bin/kafka-server-start.sh config/server.properties &> "${log_dir}/kafka.log" &

echo "Creating topic: ${topic}"
bin/kafka-topics.sh --create \
                    --zookeeper localhost:2181 \
                    --replication-factor 1 \
                    --partitions 1 \
                    --topic "${topic}"

popd
