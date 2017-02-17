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

// Node labels you want to attach to a `kubelet`.
kubernetes:nodetags:KEY0=VALUE0,KEY1=VALUE1

// If role is set, must be either `master` or `worker`
kubernetes:role:master
```

##### ZEROTIER

You can attach to a zerotier.conf network.

```
// If a zerotier-network-id is set, the image tries
// to attach to the zerotier-network.
// You will get a new network interface `zt0`
zerotier:join:MY_ZEROTIER_NETWORK_ID
```



Due to the limited configuration parameters with Scaleway, it is required that you build your own image with Kubernetes certificates baked into your image. Because of this, setup is slightly more complex than I'd like it to be.

1. Spin-up an image builder instance on scaleway, and clone this repository onto it:

```bash
$ git clone https://github.com/munnerz/scaleway-k8s.git
```

2. Place your keys, certificate, cluster CA and auth files into rootfs/etc/kubernetes:

* `apiserver-key.pem`: the apiserver private key
* `apiserver.pem`: the api server certificate
* `basic_auth.csv`: basic auth accounts
* `ca.pem`: the cluster CA certificate
* `known_tokens.csv`: token auth accounts

You can generate the openssl certificates using the CoreOS guide: https://coreos.com/kubernetes/docs/latest/openssl.html

3. Run `make install` - this by default will write everything needed to the volume attached to your builder instance at `/dev/nbd1`. To change the volume name, set the `DISK` environment variables (eg. `DISK=/dev/vdb make install`)

4. Shut down your builder instance and snapshot the attached disk. You can then create an image from this snapshot and then a new VM from your new image.

5. When creating the new servers, make sure to select the `docker` boot script.

6. If you start a new cluster you need an etcd discovery link as start point. You can get one at https://discovery.etcd.io/new?size=3 (adjust the `size` parameter according to how many etcd nodes you will initially have in your cluster)

7. Add your discover link as a tag to your server in format discover:https://discovery.etcd.io/secretkeyyougot. Make sure it is the first tag!

8. Set a second tag with your Scaleway access key and token in format api:accesskey:token.

Repeat steps 5-8 for each instance that should be in your etcd cluster.

The cluster will take a few minutes to properly come online.
