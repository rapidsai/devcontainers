#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages curl tar ca-certificates;

SYFT_VER="${SYFTVER:-latest}";
OUTPUT_PATH="${OUTPUTPATH:-/sbom/sbom.json}";

if [[ "${SYFT_VER}" == "latest" ]]; then
    find_version_from_git_tags SYFT_VER https://github.com/anchore/syft;
fi

case "${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}" in
    amd64|x86_64)
        SYFT_ARCH="linux_amd64";
        ;;
    arm64|aarch64)
        SYFT_ARCH="linux_arm64";
        ;;
    *)
        echo "Unsupported architecture: ${TARGETARCH:-$(uname -m)}" >&2;
        exit 1;
        ;;
esac

TMP_DIR="$(mktemp -d)";
trap 'rm -rf "${TMP_DIR}"' EXIT;

curl -sSfL "https://github.com/anchore/syft/releases/download/v${SYFT_VER}/syft_${SYFT_VER}_${SYFT_ARCH}.tar.gz" \
    | tar -xz -C "${TMP_DIR}" syft;

install -m 0755 "${TMP_DIR}/syft" /usr/local/bin/syft;

mkdir -p "$(dirname "${OUTPUT_PATH}")";

syft scan \
    --scope all-layers \
    --output "cyclonedx-json@1.6=${OUTPUT_PATH}" \
    dir:/;

chmod 0644 "${OUTPUT_PATH}";

