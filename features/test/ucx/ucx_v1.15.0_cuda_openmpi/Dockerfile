FROM ubuntu:22.04

RUN apt update -y \
 && DEBIAN_FRONTEND=noninteractive apt install -y \
    libopenmpi-dev \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/*;
