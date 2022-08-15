#! /usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IMAGE_REPO=docker.io/kameshsampath
BUILDER=buildx-multi-arch
NEXUS_DOCKER_FILE=$SCRIPT_DIR/Dockerfile
NEXUS_CONFIG_DOCKER_FILE=$SCRIPT_DIR/Dockerfile
NEXUS_VERSION=3.41.0-01
NEXUS_CONFIG_VERSION=$(svu patch)

docker buildx inspect "$BUILDER" || docker buildx create --name="$BUILDER" --driver=docker-container --driver-opt=network=host

docker pull "$IMAGE_REPO/nexus3:$NEXUS_VERSION" || echo "Failure: Tag already exists"

docker buildx build --push \
  --builder="$BUILDER" \
  --platform=linux/amd64,linux/arm64 \
  --build-arg TAG=$NEXUS_VERSION \
  --tag="$IMAGE_REPO/nexus3:$NEXUS_VERSION" \
  -f "$NEXUS_DOCKER_FILE" .

docker buildx build \
  --push \
  --builder="$BUILDER" \
  --platform=linux/amd64,linux/arm64 \
  --build-arg TAG="${NEXUS_CONFIG_VERSION:1}" \
  --tag="$IMAGE_REPO/nexus3-config:${NEXUS_CONFIG_VERSION:1}" \
  -f "$NEXUS_CONFIG_DOCKER_FILE" .

docker tag "$IMAGE_REPO/nexus3:$NEXUS_VERSION" "$IMAGE_REPO/nexus3:latest"
docker push "$IMAGE_REPO/nexus3:latest"

docker tag "$IMAGE_REPO/nexus3-config:${NEXUS_CONFIG_VERSION:1}" "$IMAGE_REPO/nexus3-config:latest"
docker push "$IMAGE_REPO/nexus3-config:latest"