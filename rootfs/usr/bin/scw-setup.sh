#!/bin/bash

if [ ! -f /etc/scw-int-done-setup ]; then
    SCW_HOSTNAME=$(scw-metadata | grep -Po '^HOSTNAME=\K(.*)$')
    SCW_ID=$(scw-metadata | grep -Po '^ID=\K(.*)$')
    SCW_DNSNAME_PRIVATE="$SCW_ID.priv.cloud.scaleway.com"
    SCW_DNSNAME_PUBLIC="$SCW_ID.pub.cloud.scaleway.com"
    SCW_IPV4_PRIVATE=$(scw-metadata | grep -Po '^PRIVATE_IP=\K(.*)$')
    SCW_IPV4_PUBLIC=$(scw-metadata | grep -Po '^PUBLIC_IP_ADDRESS=\K(.*)$')
    SCW_IPV6_ADDRESS=$(scw-metadata | grep -Po '^PIPV6_ADDRESS=\K(.*)$')
    SCW_IPV6_GATEWAY=$(scw-metadata | grep -Po '^PIPV6_GATEWAY=\K(.*)$')
    SCW_IPV6_NETMASK=$(scw-metadata | grep -Po '^PIPV6_NETMASK=\K(.*)$')
    SCW_MODEL=$(scw-metadata | grep -Po '^COMMERCIAL_TYPE=\K(.*)$')
    SCW_TOKEN=$(scw-server-tags | grep -Po '^scaleway:token:\K(.*)$')
    echo "SCW_ID=$SCW_ID" >>/etc/scw-env
    echo "SCW_HOSTNAME=$SCW_HOSTNAME" >>/etc/scw-env
    echo "SCW_DNSNAME_PRIVATE=$SCW_DNSNAME_PRIVATE" >>/etc/scw-env
    echo "SCW_DNSNAME_PUBLIC=$SCW_DNSNAME_PUBLIC" >> /etc/scw-env
    echo "SCW_IPV4_PRIVATE=$SCW_IPV4_PRIVATE" >>/etc/scw-env
    echo "SCW_IPV4_PUBLIC=$SCW_IPV4_PUBLIC" >>/etc/scw-env
    echo "SCW_IPV6_ADDRESS=$SCW_IPV6_ADDRESS" >>/etc/scw-env
    echo "SCW_IPV6_GATEWAY=$SCW_IPV6_GATEWAY" >>/etc/scw-env
    echo "SCW_IPV6_NETMASK=$SCW_IPV6_NETMASK" >>/etc/scw-env
    echo "SCW_MODEL=$SCW_MODEL" >>/etc/scw-env
    echo "SCW_TOKEN=$SCW_TOKEN" >>/etc/scw-env


    ETCD_CLUSTERNAME=$(scw-server-tags | grep -Po '^etcd:clustername:\K(.*)$')
    ETCD_DISCOVERY_TOKEN=$(scw-server-tags | grep -Po '^etcd:discover:\K(.*)$')
    ETCD_IS_PEER=$(scw-server-tags | grep -Po '^etcd:ispeer:\K(.*)$')
    ETCD_IS_PROXY=$(scw-server-tags | grep -Po '^etcd:isproxy:\K(.*)$')

    echo "ETCD_CLUSTERNAME=$ETCD_CLUSTERNAME" >>/etc/scw-env
    echo "ETCD_DISCOVERY_TOKEN=$ETCD_DISCOVERY_TOKEN" >>/etc/scw-env
    echo "ETCD_NAME_NODE=$SCW_ID" >>/etc/scw-env
    echo "ETCD_ADVERTISE_CLIENT_URLS=https://$SCW_DNSNAME_PRIVATE:2379" >>/etc/scw-env
    echo "ETCD_INITIAL_ADVERTISE_PEER_URLS=https://$SCW_DNSNAME_PRIVATE:2380" >>/etc/scw-env
    echo "ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379" >>/etc/scw-env
    echo "ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380" >>/etc/scw-env

    # map true/false to proxy config
    if [[ $ETCD_IS_PROXY == "true" ]]
    then
        echo "ETCD_IS_PROXY=on" >>/etc/scw-env

        # request that we actually launch etcd
        touch /etc/scw-needs-etcd-service
    else
        echo "ETCD_IS_PROXY=off" >>/etc/scw-env
    fi

    # whether to actually launch the etcd.service
    if [[ $ETCD_IS_PEER == "true" ]]
    then
        echo "ETCD_IS_PEER=true" >>/etc/scw-env

        # request that we actually launch etcd
        touch /etc/scw-needs-etcd-service
    else
        echo "ETCD_IS_PEER=false" >>/etc/scw-env
    fi

    KUBERNETES_ROLE=$(scw-server-tags | grep -Po '^kubernetes:role:\K(.*)$')
    echo "KUBERNETES_ROLE=$KUBERNETES_ROLE" >> /etc/scw-env

    ZEROTIER_NETWORK_ID=$(scw-server-tags | grep -Po '^zerotier:join:\K(.*)$')
    echo "ZEROTIER_NETWORK_ID=$ZEROTIER_NETWORK_ID" >> /etc/scw-env

    chmod +x /etc/scw-env
    touch /etc/scw-int-done-setup
fi

exit 0
