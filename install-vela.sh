#!/bin/bash

# The vela CLI baked into the image. Independent of the image tag: the image has
# its own release cadence, the CLI follows KubeVela's.
VELA_VERSION=${VELA_VERSION:-"v1.11.0"}

PLATFORM=linux-amd64

if [ "$BUILDPLATFORM" == "linux/arm64" ]
then
    PLATFORM=linux-arm64
fi

ARCHIVE=vela-$VELA_VERSION-$PLATFORM.tar.gz
URL=https://github.com/kubevela/kubevela/releases/download/$VELA_VERSION/$ARCHIVE
echo "Download the binary from: $URL"

# -f so a missing release fails here rather than unpacking an HTML error page.
curl -fsSL -o "$ARCHIVE" "$URL" || exit 1
if [ ! -d "vela" ]; then
  mkdir -p vela
fi

tar -zxf "$ARCHIVE" -C vela || exit 1
mv vela/$PLATFORM/vela /usr/local/bin/vela || exit 1
rm "$ARCHIVE"
rm -r vela
vela version
