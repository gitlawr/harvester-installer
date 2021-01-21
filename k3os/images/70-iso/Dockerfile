# syntax=docker/dockerfile:experimental
ARG REPO
ARG TAG
FROM ${REPO}/k3os-package:${TAG} as package

ARG REPO
ARG TAG
FROM ${REPO}/k3os-base:${TAG} as base
ARG VERSION
ARG ARCH
RUN apk add xorriso grub grub-efi mtools libvirt qemu-img
RUN if [ "$ARCH" == "amd64" ]; then \
        apk add qemu-system-x86_64 grub-bios ovmf \
    ;elif [ "$ARCH" == "arm64" ]; then \
        apk add qemu-system-aarch64 \
    ;fi
RUN ln -s /usr/bin/qemu-system-* /usr/bin/qemu-system
RUN qemu-img create -f qcow2 /hd.img 40G
COPY run-kvm.sh /usr/bin/
COPY grub.cfg /usr/src/iso/boot/grub/grub.cfg

COPY --from=package /output/ /usr/src/iso/

COPY config.yaml /usr/src/iso/k3os/system/

RUN mkdir -p /usr/src/iso/var/lib/rancher/k3s/agent/images \
    /usr/src/iso/var/lib/rancher/k3s/server/static/charts \
    /usr/src/iso/var/lib/rancher/k3s/server/manifests
COPY charts/* /usr/src/iso/var/lib/rancher/k3s/server/static/charts
COPY manifests/* /usr/src/iso/var/lib/rancher/k3s/server/manifests
RUN --mount=type=bind,source=/,target=/ctx cp /ctx/harvester-images.tar.zst \
    /usr/src/iso/var/lib/rancher/k3s/agent/images &>/dev/null || true

RUN mkdir -p /output && \
    grub-mkrescue -o /output/k3os.iso /usr/src/iso/. -- -volid K3OS -joliet on && \
    [ -e /output/k3os.iso ] # grub-mkrescue doesn't exit non-zero on failure

CMD ["run-kvm.sh"]
