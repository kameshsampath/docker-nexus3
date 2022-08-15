#! /usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IMAGE_REPO=docker.io/kameshsampath
BUILDER=buildx-multi-arch
NEXUS_CONFIG_DOCKER_FILE=$SCRIPT_DIR/Dockerfile.sidecar
NEXUS_VERSION=3.41.0-01
NEXUS_CONFIG_VERSION=${NEXUS_VERSION}

docker buildx inspect "$BUILDER" || docker buildx create --name="$BUILDER" --driver=docker-container --driver-opt=network=host

docker buildx build \
  --push \
  --builder="$BUILDER" \
  --platform=linux/amd64,linux/arm64 \
  --build-arg TAG="${NEXUS_CONFIG_VERSION}" \
  --tag="$IMAGE_REPO/nexus3-config:${NEXUS_CONFIG_VERSION}" \
  --tag="$IMAGE_REPO/nexus3-config:latest" \
  -f "$NEXUS_CONFIG_DOCKER_FILE" .