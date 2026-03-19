# syntax=docker/dockerfile:1.6
ARG SYFT_VERSION
ARG SOURCE_IMAGE_NAME

FROM --platform=$BUILDPLATFORM alpine:3.20 AS syft-base
ARG BUILDPLATFORM
ARG SYFT_VERSION
RUN apk add --no-cache curl tar ca-certificates \
 && case "$BUILDPLATFORM" in \
      linux/amd64) SYFT_ARCH="linux_amd64" ;; \
      linux/arm64) SYFT_ARCH="linux_arm64" ;; \
      *) echo "Unsupported BUILDPLATFORM: ${BUILDPLATFORM}" >&2 && exit 1 ;; \
    esac \
 && curl -sSfL "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_${SYFT_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin syft \
 && chmod +x /usr/local/bin/syft

FROM base AS devcontainer-base

FROM syft-base AS sbom
RUN --mount=type=bind,from=devcontainer-base,source=/,target=/rootfs,ro \
    mkdir -p /out && \
    syft scan \
      --source-name "${SOURCE_IMAGE_NAME}" \
      --scope all-layers \
      --output cyclonedx-json@1.6=/out/sbom.json \
      dir:/rootfs

FROM devcontainer-base
RUN mkdir -p /sbom
COPY --from=sbom /out/sbom.json /sbom/sbom.json
