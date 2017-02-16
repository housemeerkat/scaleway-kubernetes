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

# Install docker dependencies & upgrade system
RUN apt-get -q update \
        && apt-get -y -qq upgrade \
        && apt-get install -y -q \
        apparmor \
        arping \
        aufs-tools \
        btrfs-tools \
        bridge-utils \
        cgroupfs-mount \
        jq \
        git \
        ifupdown \
        kmod \
        lxc \
        python-setuptools \
        software-properties-common \
        vlan \
        && apt-get clean

# Install docker
RUN curl -L https://get.docker.com/ | sh

# Install kubernetes and zerotierone tools
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | apt-key add -
RUN add-apt-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main' \
  && add-apt-repository 'deb http://download.zerotier.com/debian/xenial xenial main' \
  && apt-get -q update \
	&& apt-get -y -qq upgrade \
	&& apt-get install -y -q \
  jq \
  kubectl \
  kubelet \
  zerotier-one \
  && apt-get clean

# Add local files into the root (extra config etc)
COPY ./rootfs/ /

# Add early-docker group
RUN addgroup early-docker

RUN systemctl disable docker \
    && systemctl enable docker \
    && systemctl enable early-docker \
    && systemctl enable etcd

# Clean rootfs from image-builder.
#   Revert the builder-enter script
RUN /usr/local/sbin/builder-leave
