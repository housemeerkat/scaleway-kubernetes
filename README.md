# scaleway-kubernetes
Scaleway image to run Kubernetes

This will create a highly-available (multi-master) Kubernetes cluster on top of scaleway, built on top of the scaleway docker image. Currently, this has only been tested with x86_64.

Because scaleway does not support multiple-IPs per server, nor does it support loadbalancers, you'll need to use round-robin DNS to balance traffic across each Kubernetes node.

---

## Setup

Supported tags:

##### Scaleway/Firewall

Since Scaleway's firewall has an ALLOW per default,
you might want to configure an additional firewall per node.

```
scaleway:token:YOUR_SCALEWAY_TOKEN
```

##### ETCD

You can use this image to generate an ETCD cluster by being a peer-node, or launch an ETCD proxy to attach to a remote ETCD cluster.
If you do not pass either peer-related params or proxy-related-params, no
etcd.service will be launched.

```
// specify that this machine uses an etcd-cluster with the name: MY_ETCD_CLUSTER_NAME
// use this variable, if you somehow need to access the etcd-cluster, either as
// a peer or as an etcd-client.
etcd:clustername:MY_ETCD_CLUSTER_NAME

// An etcd discovery token from https://discovery.etcd.io/new?size=3
// Be aware to specify the correct size.
etcd:discover:https://discovery.etcd.io/56271f6167a9cecdd86b3e84320185d0

// Whether this node should be an etcd-peer [Default:false]
etcd:ispeer:false

// Whether this node should act as an etcd-proxy [Default:false]
etcd:isproxy:false
```

##### KUBERNETES

Apart from being an etcd-node, this image can as well
be used to lauch a kubernetes master or worker.

```
// specify that this machine uses an kubernetes-cluster with the name:
// MY_KUBERNETES_CLUSTER_NAME
// use this variable, if you somehow need to access the kubernetes-cluster.
// This is the case for all nodes (master/worker), where `kubelet` is installed
kubernetes:clustername:MY_KUBERNETES_CLUSTER_NAME

// specify a load-balanced URL, which contains all DNS names for master-nodes
// fallback is the first master-url, which can be autodiscovered.
// This can be done afterwards. Put all master-nodes into a Route53 DNS with
// multiple A records
kubernetes:master:url:LOAD_BALANCED_URL_OF_APISERVER

// Node labels you want to attach to a `kubelet`.
kubernetes:nodetags:KEY0=VALUE0,KEY1=VALUE1

// If role is set, must be either `master` or `worker`
kubernetes:role:master
```

##### ZEROTIER (jump-host)

Zerotier.com is a SDN, which can be used to form a private network across
datacenter boundaries.
This could be used as a jump-host/bastion-host to get into the Scaleway network.
(unused)

```sh
// If a zerotier-network-id is set, the image tries
// to attach to the zerotier-network.
// You will get a new network interface `zt0`
zerotier:join:MY_ZEROTIER_NETWORK_ID
```

### Build new image on Scaleway

- Create new ImageBuilder instance on Scaleway with an **additional** 50GB
  volume
- Launch instance

```
# login to your Scaleway Imagebuilder instance
ssh imagebuilder

# checkout this repo
git clone https://github.com/iosphere/scaleway-kubernetes.git

# Goto directory
cd scaleway-kubernetes

# Show make targets
make

# Make local image on additional 50gb volume
make install_on_disk

# Copy image to your private Scaleway image registry
make image_on_local

# Logout
exit
```




