FROM rancher/k3os:v0.19.5-rc.1 as k3os

FROM ubuntu:18.04
RUN apt-get update && apt-get install -y zstd
COPY --from=k3os /k3os/system/ /k3os/system/
COPY harvester-0.1.1.tgz /harvester-0.1.1.tgz
COPY prepare.sh /prepare.sh
ENV PATH /k3os/system/k3os/current:/k3os/system/k3s/current:${PATH}
ENTRYPOINT ["k3os"]
CMD ["help"]
