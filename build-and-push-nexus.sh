#! /usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IMAGE_REPO=docker.io/kameshsampath
BUILDER=buildx-multi-arch
NEXUS_DOCKER_FILE=$SCRIPT_DIR/Dockerfile
NEXUS_VERSION=3.41.0-01

docker buildx inspect "$BUILDER" || docker buildx create --name="$BUILDER" --driver=docker-container --driver-opt=network=host

docker pull "$IMAGE_REPO/nexus3:$NEXUS_VERSION" || echo "Failure: Tag already exists"

docker buildx build --push \
  --builder="$BUILDER" \
  --platform=linux/amd64,linux/arm64 \
  --build-arg TAG=$NEXUS_VERSION \
  --tag="$IMAGE_REPO/nexus3:$NEXUS_VERSION" \
  --tag="$IMAGE_REPO/nexus3:latest" \
  -f "$NEXUS_DOCKER_FILE" .
