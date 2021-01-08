#!/bin/bash

if [ -d /host/var/lib/rancher/k3s/server/static/charts ];then
  cp /harvester*.tgz /host/var/lib/rancher/k3s/server/static/charts/
  echo "Copied the Harvester chart"
fi

if [ -d /host/var/lib/rancher/k3s/server/manifests ];then
  cp /manifests/* /host/var/lib/rancher/k3s/server/manifests/
  echo "Copied manifests"
fi

