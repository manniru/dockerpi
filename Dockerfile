ARG QEMU_VERSION=4.2.0

FROM debian:stable-slim AS qemu
LABEL maintainer="Luke Childs <lukechilds123@gmail.com>"
ARG QEMU_VERSION

# RUN apt-get update && \
#     apt-get -y install wget gpg git python gcc make pkg-config libglib2.0-dev zlib1g-dev libpixman-1-dev flex bison

RUN apt-get update && \
    apt-get -y install wget gpg

RUN cd /tmp && \
    qemu_tarball="qemu-${QEMU_VERSION}.tar.xz" && \
    wget "https://download.qemu.org/${qemu_tarball}" && \
    wget "https://download.qemu.org/${qemu_tarball}.sig" && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys CEACC9E15534EBABB82D3FA03353C9CEF108B584 && \
    gpg --verify "${qemu_tarball}.sig" "${qemu_tarball}" && \
    tar xvf "${qemu_tarball}"

RUN apt-get -y install git python gcc make pkg-config libglib2.0-dev zlib1g-dev libpixman-1-dev flex bison

RUN cd /tmp && \
    cd "qemu-${QEMU_VERSION}" && \
    mkdir build && \
    cd build && \
    ../configure --static --target-list=arm-softmmu && \
    make -j$(nproc) && \
    strip "/tmp/qemu-${QEMU_VERSION}/build/arm-softmmu/qemu-system-arm" && \
    mv "/tmp/qemu-${QEMU_VERSION}/build/arm-softmmu/qemu-system-arm" /usr/local/bin/qemu-system-arm && \
    apt-get purge -y wget gpg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM busybox AS dockerpi-vm
LABEL maintainer="Luke Childs <lukechilds123@gmail.com>"
ARG QEMU_VERSION

COPY --from=qemu /usr/local/bin/qemu-system-arm /usr/local/bin/qemu-system-arm

ADD https://github.com/dhruvvyas90/qemu-rpi-kernel/archive/afe411f2c9b04730bcc6b2168cdc9adca224227c.zip /tmp/qemu-rpi-kernel.zip

RUN cd /tmp && \
    mkdir -p /root/qemu-rpi-kernel && \
    unzip qemu-rpi-kernel.zip && \
    cp -r qemu-rpi-kernel-*/* /root/qemu-rpi-kernel/ && \
    rm -rf /tmp/* /root/qemu-rpi-kernel/README.md /root/qemu-rpi-kernel/tools

VOLUME /sdcard

ADD ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

FROM dockerpi-vm as dockerpi
LABEL maintainer="Luke Childs <lukechilds123@gmail.com>"
ADD http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip /filesystem.zip
