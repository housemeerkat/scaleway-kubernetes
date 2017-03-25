## -*- docker-image-name: "scaleway/kubernetes" -*-
FROM scaleway/ubuntu:amd64-xenial
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/ubuntu:armhf-xenial     # arch=armv7l
#FROM scaleway/ubuntu:arm64-xenial     # arch=arm64
#FROM scaleway/ubuntu:i386-xenial      # arch=i386
#FROM scaleway/ubuntu:mips-xenial      # arch=mips

# Prepare rootfs for image-builder.
#   This script prevent aptitude to run services when installed
RUN /usr/local/sbin/builder-enter

RUN curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | apt-key add -
RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -


# Install docker dependencies & upgrade system
RUN apt-get -q update \
        && apt-get -y -qq upgrade \
        && apt-get install -y -q \
        software-properties-common \
        apt-transport-https \
        && add-apt-repository 'deb http://download.zerotier.com/debian/xenial xenial main' \
        && add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable' \
        && apt-get -q update \
        && apt-get install -y -q \
        apparmor \
        arping \
        aufs-tools \
        btrfs-tools \
        bridge-utils \
        cgroupfs-mount \
        docker-ce \
        jq \
        git \
        ifupdown \
        kmod \
        lxc \
        python-setuptools \
        ufw \
        vlan \
        zerotier-one \
        && apt-get clean

# Install CNI plugins for kubelet cni mode
RUN mkdir -p /opt/cni/bin \
    && mkdir -p /etc/cni/net.d \
    && curl -fsSL 'https://github.com/containernetworking/cni/releases/download/v0.5.1/cni-amd64-v0.5.1.tgz' | tar xvz -C /opt/cni/bin/


# Add local files into the root (extra config etc)
COPY ./rootfs/ /

# Add early-docker group
RUN addgroup early-docker

RUN systemctl disable docker \
    && systemctl enable docker \
    && systemctl enable early-docker \
    && systemctl enable etcd

# Force new machine-ids for every new image.
# Otherwise you might get ARP problems with duplicate mac addresses on the
# same host.
RUN rm -f /etc/machine-id /var/lib/dbus/machine-id

# Clean rootfs from image-builder.
#   Revert the builder-enter script
RUN /usr/local/sbin/builder-leave
