#!/bin/bash

rm -f /etc/scw-env
rm -f /tmp/scw-needs-etcd-service
rm -f /tmp/scw-needs-kubeadm-service

SCW_HOSTNAME=$(scw-metadata | grep -Po '^HOSTNAME=\K(.*)$')
SCW_ID=$(scw-metadata | grep -Po '^ID=\K(.*)$')
SCW_DNSNAME_PRIVATE="$SCW_ID.priv.cloud.scaleway.com"
SCW_DNSNAME_PUBLIC="$SCW_ID.pub.cloud.scaleway.com"
SCW_IPV4_PRIVATE=$(scw-metadata | grep -Po '^PRIVATE_IP=\K(.*)$')
SCW_IPV4_PUBLIC=$(scw-metadata | grep -Po '^PUBLIC_IP_ADDRESS=\K(.*)$')
SCW_IPV6_ADDRESS=$(scw-metadata | grep -Po '^PIPV6_ADDRESS=\K(.*)$')
SCW_IPV6_GATEWAY=$(scw-metadata | grep -Po '^PIPV6_GATEWAY=\K(.*)$')
SCW_IPV6_NETMASK=$(scw-metadata | grep -Po '^PIPV6_NETMASK=\K(.*)$')
SCW_LOCATION_CLUSTER_ID=$(scw-metadata | grep -Po '^LOCATION_CLUSTER_ID=\K(.*)$')
SCW_LOCATION_HYPERVISOR_ID=$(scw-metadata | grep -Po '^LOCATION_HYPERVISOR_ID=\K(.*)$')
SCW_LOCATION_NODE_ID=$(scw-metadata | grep -Po '^LOCATION_NODE_ID=\K(.*)$')
SCW_LOCATION_PLATFORM_ID=$(scw-metadata | grep -Po '^LOCATION_PLATFORM_ID=\K(.*)$')
SCW_LOCATION_ZONE_ID=$(scw-metadata | grep -Po '^LOCATION_ZONE_ID=\K(.*)$')
SCW_MODEL=$(scw-metadata | grep -Po '^COMMERCIAL_TYPE=\K(.*)$')
SCW_REGION=$SCW_LOCATION_ZONE_ID
SCW_API_ENDPOINT="https://cp-${SCW_REGION}.scaleway.com/servers"
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
echo "SCW_REGION=$SCW_REGION" >> /etc/scw-env
echo "SCW_TOKEN=$SCW_TOKEN" >>/etc/scw-env

KUBEADM_TOKEN=$(scw-server-tags | grep -Po '^kubernetes:kubeadm:token:\K(.*)$')

KUBERNETES_MASTER_URL=$(scw-server-tags | grep -Po '^kubernetes:master:url:\K(.*)$')
KUBERNETES_VERSION=$(scw-server-tags | grep -Po '^kubernetes:version:\K(.*)$') || "v1.5.5"

echo "KUBERNETES_MASTER_URL=$KUBERNETES_MASTER_URL" >>/etc/scw-env
echo "KUBEADM_TOKEN=$KUBEADM_TOKEN" >>/etc/scw-env
echo "KUBERNETES_VERSION=$KUBERNETES_VERSION" >>/etc/scw-env

# whether to actually launch the etcd.service
# and whether we want to schedule containers on masters
if [[ $KUBERNETES_ROLE == "master" ]]
then
  # request that we actually launch kubectl.service
  touch /tmp/scw-needs-kubeadm-service

elif [[ $KUBERNETES_ROLE == "worker" ]]
then
  touch /tmp/scw-needs-kubeadm-join
fi

ZEROTIER_NETWORK_ID=$(scw-server-tags | grep -Po '^zerotier:join:\K(.*)$')
echo "ZEROTIER_NETWORK_ID=$ZEROTIER_NETWORK_ID" >> /etc/scw-env

chmod +x /etc/scw-env

exit 0
