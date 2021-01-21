#!/bin/bash
set -e

DISTRO=/run/k3os/iso

if [ "$K3OS_DEBUG" = true ]; then
    set -x
fi

cleanup2()
{
    if [ -n "${TARGET}" ]; then
        umount ${TARGET} || true
    fi

    losetup -d ${ISO_DEVICE} || losetup -d ${ISO_DEVICE%?} || true
    umount $DISTRO || true
}

cleanup()
{
    EXIT=$?
    cleanup2 2>/dev/null || true
    return $EXIT
}

find_installation_device()
{
    STATE=$(blkid -L HARVESTER_STATE || true)
    if [ -z "$STATE" ] && [ -n "$DEVICE" ]; then
        tune2fs -L HARVESTER_STATE $DEVICE
        STATE=$(blkid -L HARVESTER_STATE)
    fi

    return 0
}

do_mount()
{
    TARGET=/run/k3os/target
    mkdir -p ${TARGET}
    mount ${STATE} ${TARGET}

    mkdir -p ${DISTRO}
    mount -o ro ${ISO_DEVICE} ${DISTRO} || mount -o ro ${ISO_DEVICE%?} ${DISTRO}
}

do_copy()
{
    echo "Copying files"
    chart_path="var/lib/rancher/k3s/server/static/charts"
    manifest_path="var/lib/rancher/k3s/server/manifests"
    cp ${DISTRO}/${chart_path}/* ${TARGET}/k3os/data/${chart_path}/
    cp ${DISTRO}/${manifest_path}/* ${TARGET}/k3os/data/${manifest_path}/

    #copy offline artifacts and decompress offline images
    root_path="${TARGET}/k3os/data"
    offline_image_path="var/lib/rancher/k3s/agent/images/harvester-images.tar"
    if [ -f "${DISTRO}/${offline_image_path}.zst" ]; then
        prepare_images
    fi
}

prepare_images()
{
    #copy offline artifacts and decompress offline images
    mkdir -p "${root_path}"
    cp ${DISTRO}/${offline_image_path}.zst ${root_path}/${offline_image_path}.zst
    echo "Decompressing container images"
    zstd -d -f --rm "${root_path}/${offline_image_path}.zst" -o "${root_path}/${offline_image_path}" > /dev/null


    echo "Loading images. This may take a few minutes"
    cd ${root_path}
    rm bin lib sbin
    mkdir lib bin sbin
    mount --bind /bin bin
    mount --bind /sbin sbin
    mount --bind /run/k3os/iso/k3os k3os
    mount --bind /dev dev
    mount --bind /proc proc
    mount --bind /etc etc
    mount -r --rbind /lib lib
    mount -r --rbind /sys sys
    chroot . /bin/bash <<"EOF"
    # invoke k3s to set up data dir
    k3s agent --no-flannel &>/dev/null || true
    # start containerd
    /var/lib/rancher/k3s/data/current/bin/containerd \
    -c /var/lib/rancher/k3s/agent/etc/containerd/config.toml \
    -a /run/k3s/containerd/containerd.sock \
    --state /run/k3s/containerd \
    --root /var/lib/rancher/k3s/agent/containerd &>/dev/null &

    #wait for containerd to be ready
    until ctr --connect-timeout 1s version>/dev/null
    do
      sleep 1
    done
    # import images
    ctr -n k8s.io images import /var/lib/rancher/k3s/agent/images/harvester*
    rm /var/lib/rancher/k3s/agent/images/harvester*
    # stop containerd
    pkill containerd
    exit
EOF
    sleep 5
    #cleanup
    umount bin sbin k3os dev proc etc
    mount --make-rslave lib
    mount --make-rslave sys
    umount -R lib
    umount -R sys
    rm -r lib bin sbin
}

do_upgrade()
{
  echo "Upgrading OS"
  k3os --debug upgrade --kernel --rootfs --source=/k3os/system --destination=${TARGET}/k3os/system
}

get_iso()
{
    ISO_DEVICE=$(blkid -L K3OS || true)
    if [ -z "${ISO_DEVICE}" ]; then
        for i in $(lsblk -o NAME,TYPE -n | grep -w disk | awk '{print $1}'); do
            mkdir -p ${DISTRO}
            if mount -o ro /dev/$i ${DISTRO}; then
                ISO_DEVICE="/dev/$i"
                umount ${DISTRO}
                break
            fi
        done
    fi

    if [ -z "${ISO_DEVICE}" ]; then
        echo "#### There is no k3os ISO device"
        return 1
    fi
}

while [ "$#" -gt 0 ]; do
    case $1 in
        --debug)
            set -x
            ;;
        *)
            break
            ;;
    esac
    shift 1
done

trap cleanup exit

get_iso
find_installation_device
do_mount
do_copy
do_upgrade

if grep -q 'k3os.install.power_off=true' /proc/cmdline; then
    poweroff -f
else
    echo " * Upgrade completed"
    echo " * Rebooting system in 5 seconds"
    sleep 5
    reboot -f
fi
