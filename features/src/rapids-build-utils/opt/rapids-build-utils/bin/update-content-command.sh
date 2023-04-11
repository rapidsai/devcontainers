#! /usr/bin/env -S bash -Eeuo pipefail

mkdir -m 0755 -p ~/{.aws,.cache,.conda,.config};

rapids-generate-scripts;
