ARG TAG
FROM rancher/k3os:${TAG} as k3os

FROM ubuntu:18.04

ARG ARCH=amd64
ENV KUBECTL_VERSION v1.20.4

COPY --from=k3os /k3os/system/ /k3os/system/
COPY harvester-*.tgz /
COPY upgrade_node.sh /usr/local/bin/upgrade_node.sh
COPY manifests /manifests
ENV PATH /k3os/system/k3os/current:/k3os/system/k3s/current:${PATH}

RUN apt-get update && apt-get install -y curl && \
    curl -sLf https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl
CMD ["upgrade_node.sh"]
