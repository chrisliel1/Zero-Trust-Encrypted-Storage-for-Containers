FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    time \
    coreutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN useradd -m -u 1001 -s /bin/bash appuser && \
    echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appuser && \
    chmod 0440 /etc/sudoers.d/appuser && \
    mkdir -p /app/nfs_test && chown -R appuser:appuser /app

WORKDIR /app
USER appuser

ENTRYPOINT ["tail", "-f", "/dev/null"]
