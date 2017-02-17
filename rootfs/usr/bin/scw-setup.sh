#!/bin/bash

rm -f /etc/scw-env
rm -f /tmp/scw-needs-etcd-service
rm -f /tmp/scw-needs-kubelet-service

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

# query the Scaleway API and find all `etcd:ispeer:true` belonging to this ETCD_CLUSTERNAME
ETCD_PEERS=$(
curl --silent \
  --fail \
  -H "X-Auth-Token: ${SCW_TOKEN}" \
  -H 'Content-Type: application/json' \
  https://cp-par1.scaleway.com/servers | jq '[.servers[] | select((.tags[] | contains("etcd:ispeer:true")) and (.tags[] | contains("etcd:clustername:'$ETCD_CLUSTERNAME'"))) | ["\(.id).priv.cloud.scaleway.com"]] | add | unique | join(",")'
)

echo "ETCD_CLUSTERNAME=$ETCD_CLUSTERNAME" >>/etc/scw-env
echo "ETCD_DISCOVERY_TOKEN=$ETCD_DISCOVERY_TOKEN" >>/etc/scw-env
echo "ETCD_PEERS=$ETCD_PEERS" >>/etc/scw-env
echo "ETCD_NAME_NODE=$SCW_ID" >>/etc/scw-env

# Should only be accessible from within the datacenter network.
echo "ETCD_ADVERTISE_CLIENT_URLS=https://$SCW_DNSNAME_PRIVATE:2379" >>/etc/scw-env
echo "ETCD_INITIAL_ADVERTISE_PEER_URLS=https://$SCW_DNSNAME_PRIVATE:2380" >>/etc/scw-env

# This must be an IP-Address unless you use DNS-SRV discovery for etcd.
# Be aware that the private IP will change if you terminate your machine.
echo "ETCD_LISTEN_CLIENT_URLS=http://127.0.0.1:2379,https://127.0.0.1:2379,https://$SCW_IPV4_PRIVATE:2379" >>/etc/scw-env
echo "ETCD_LISTEN_PEER_URLS=https://$SCW_IPV4_PRIVATE:2380" >>/etc/scw-env

# map true/false to proxy config
if [[ $ETCD_IS_PROXY == "true" ]]
then
  echo "ETCD_IS_PROXY=on" >>/etc/scw-env

  # request that we actually launch etcd.service
  touch /tmp/scw-needs-etcd-service
else
  echo "ETCD_IS_PROXY=off" >>/etc/scw-env
fi

# whether to actually launch the etcd.service
if [[ $ETCD_IS_PEER == "true" ]]
then
  echo "ETCD_IS_PEER=true" >>/etc/scw-env

  # request that we actually launch etcd.service
  touch /tmp/scw-needs-etcd-service
else
  echo "ETCD_IS_PEER=false" >>/etc/scw-env
fi

KUBERNETES_CLUSTERNAME=$(scw-server-tags | grep -Po '^kubernetes:clustername:\K(.*)$')
# query the Scaleway API and find all `kubernetes:role:master` belonging to this KUBERNETES_CLUSTERNAME
KUBERNETES_HOSTNAME=$SCW_IPV4_PRIVATE
KUBERNETES_MASTERS=$(
curl --silent \
  --fail \
  -H "X-Auth-Token: ${SCW_TOKEN}" \
  -H 'Content-Type: application/json' \
  https://cp-par1.scaleway.com/servers | jq '[.servers[] | select((.tags[] | contains("kubernetes:role:master")) and (.tags[] | contains("kubernetes:clustername:'$KUBERNETES_CLUSTERNAME'"))) | ["\(.id).priv.cloud.scaleway.com"]] | add | unique | join(",")'
)
KUBERNETES_ROLE=$(scw-server-tags | grep -Po '^kubernetes:role:\K(.*)$')
# TODO: implement multiple tags
KUBERNETES_NODE_TAGS=$(scw-server-tags | grep -Po '^kubernetes:nodetags:\K(.*)$')
KUBERNETES_NODE_LABELS="role=${KUBERNETES_ROLE},scwmodel=${SCW_MODEL}"
KUBERNETES_MASTER_SCHEDULABLE=$(scw-server-tags | grep -Po '^kubernetes:master:schedulable:\K(.*)$')
echo "KUBERNETES_CLUSTERNAME=$KUBERNETES_CLUSTERNAME" >> /etc/scw-env
echo "KUBERNETES_HOSTNAME=$KUBERNETES_HOSTNAME" >> /etc/scw-env
echo "KUBERNETES_MASTERS=$KUBERNETES_MASTERS" >> /etc/scw-env
echo "KUBERNETES_NODE_LABELS=$KUBERNETES_NODE_LABELS" >> /etc/scw-env
echo "KUBERNETES_NODE_TAGS=$KUBERNETES_NODE_TAGS" >> /etc/scw-env
echo "KUBERNETES_ROLE=$KUBERNETES_ROLE" >> /etc/scw-env

# whether to actually launch the etcd.service
# and whether we want to schedule containers on masters
if [[ $KUBERNETES_ROLE == "master" ]]
then
  # request that we actually launch kubectl.service
  touch /tmp/scw-needs-kubelet-service

  # check, whether we explicly requested scheduling on master
  # otherwise fallback to `false
  if [[ $KUBERNETES_MASTER_SCHEDULABLE == "true" ]]
  then
    echo "KUBERNETES_REGISTER_SCHEDULABLE=true" >> /etc/scw-env
  else
    echo "KUBERNETES_REGISTER_SCHEDULABLE=false" >> /etc/scw-env
  fi
elif [[ $KUBERNETES_ROLE == "worker" ]]
then
  # request that we actually launch kubectl.service
  touch /tmp/scw-needs-kubelet-service

  # schedule pods on workers
  echo "KUBERNETES_REGISTER_SCHEDULABLE=true" >> /etc/scw-env
fi

ZEROTIER_NETWORK_ID=$(scw-server-tags | grep -Po '^zerotier:join:\K(.*)$')
echo "ZEROTIER_NETWORK_ID=$ZEROTIER_NETWORK_ID" >> /etc/scw-env

chmod +x /etc/scw-env

exit 0
