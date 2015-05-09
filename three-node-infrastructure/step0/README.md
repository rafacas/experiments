# Step 0 - Development environment

## What is docker?
[Docker](https://www.docker.com/) is an open platform for developers and sysadmins to build, ship, and run distributed applications. Docker uses resource isolation features of the Linux kernel such as cgroups and kernel namespaces to allow independent _containers_ to run within a single Linux instance, avoiding the overhead of starting virtual machines. 

To know more about Linux containers (LXC) visit the [LXC webpage](https://linuxcontainers.org/lxc/introduction/). It explains in detail how LXC is a userspace interface for the Linux kernel containment features and how through a powerful API and simple tools, it lets Linux users easily create and manage system or application containers. 

I've found very useful starting with the [Docker User Guide](https://docs.docker.com/userguide/) and also, these articles about cgroups and namespaces are very interesting. Knowing cgroups and namespaces helps understand the difference between virtual machines and containers:

* [PaaS under the hood, episode 1: kernel namespaces](http://blog.dotcloud.com/under-the-hood-linux-kernels-on-dotcloud-part)
* [PaaS Under the Hood, Episode 2: cgroups](http://blog.dotcloud.com/kernel-secrets-from-the-paas-garage-part-24-c)

## Docker architecture

Docker's main components are:

* *Docker daemon*: runs on a host machine. The user does not directly interact with the daemon, but instead through an intermediary: the Docker *client*.
* *Docker client*: is the primary user interface to Docker. It is tasked with accepting commands from the user and communicating back and forth with a Docker *daemon* to manage the container lifecycle on any host.
* *Docker Hub*: is the global archive of user supplied Docker container images. It currently hosts a large number of projects where you can find almost any popular application or deployment stack readily available to download and run with a single command.

## Boot2Docker

I'm using OSX so I cannot use this Operating System to run the docker daemon. I'll use [Boot2Docker](https://github.com/boot2docker/boot2docker), which is a lightweight Linux distribution made specifically to run Docker containers. It runs completely from RAM. It is currently designed and tuned for development. Using it for any kind of production workloads at this time is highly discouraged.

These are the installing instructions for [Mac OS X](https://docs.docker.com/installation/mac/).

The following steps will be run with the following versions:
```
$ docker version
Client version: 1.6.0
Client API version: 1.18
Go version (client): go1.4.2
Git commit (client): 4749651
OS/Arch (client): darwin/amd64
Server version: 1.6.0
Server API version: 1.18
Go version (server): go1.4.2
Git commit (server): 4749651
OS/Arch (server): linux/amd64
```

