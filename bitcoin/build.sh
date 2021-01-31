#!/bin/bash

# This build routine uses systemd-binfmt to compile target architectures
# in their native containers emulated in amd64.

IMAGE_NAME=docker.io/pocoyo/bitcoin
VERSION=v0.21.0
ARCHS=(arm64v8 arm32v7 amd64)

for arch in ${ARCHS[@]}; do
    echo "building for $arch"
    podman build --build-arg "ARCH=$arch" --build-arg "VERSION=$VERSION" --no-cache -f Dockerfile . -t $IMAGE_NAME:$arch && \
        podman push $IMAGE_NAME:$arch
done

podman image rm -f $IMAGE_NAME

podman manifest create $IMAGE_NAME && \
    podman manifest add --arch arm64 --os linux --variant v8 $IMAGE_NAME $IMAGE_NAME:arm64v8 && \
    podman manifest add --arch arm --variant v7 --os linux $IMAGE_NAME $IMAGE_NAME:arm32v7 && \
    podman manifest add $IMAGE_NAME $IMAGE_NAME:amd64 && \
    # docker prefers v2s2 manifest format over oci.
    podman manifest push --format v2s2 --all $IMAGE_NAME docker://$IMAGE_NAME:latest && \
    podman manifest push --format v2s2 --all --purge $IMAGE_NAME docker://$IMAGE_NAME:$VERSION
echo "DONE"

rm -rf bitcoin
