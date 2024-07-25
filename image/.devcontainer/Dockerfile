ARG BASE
FROM ${BASE}

ARG RAPIDS_VERSION
ENV RAPIDS_VERSION=$RAPIDS_VERSION

RUN if grep ubuntu:x:1000:1000 /etc/passwd >/dev/null; then userdel -f -r ubuntu; fi
