# Step 3 - Building and provisioning a production server (docker host)

In previous steps we've created the three-node infrastructure in a development environment. In this step we will create a production server to deploy our new infrastructure.

Our production server, that is our docker host, is based on Ubuntu 14.04. The following steps can be done independently of where the "server" is (AWS, Linode, Rackspace, Digital Ocean,...). We are going to use a virtual machine instead (so we are able to work in our local machine).

The Vagrantfile will help us to create a virtual machine that we'll use as our "production server".

The provisioning on this server will be done with [Ansible](http://www.ansible.com/home) so we need to install it in our laptop or the machine we are going to use to provision the server.

```
$ ansible --version
ansible 1.9.0.1
```

We will also install the Ansible rol [docker_ubuntu](https://galaxy.ansible.com/list#/roles/292), which will install Docker in the server.

```
$ ansible-galaxy install angstwad.docker_ubuntu
- downloading role 'docker_ubuntu', owned by angstwad
- downloading role from https://github.com/angstwad/docker.ubuntu/archive/master.tar.gz
- extracting angstwad.docker_ubuntu to /usr/local/etc/ansible/roles/angstwad.docker_ubuntu
- angstwad.docker_ubuntu was installed successfully
```

Then, we will *install* the production server. In our case, we are using Virtualbox to *simulate* a *remote* server, so we run:

```
$ vagrant up
```

In the ```ansible``` directory can be found the playbook used to provision the production server.

```
$ cd ansible
$ ansible-playbook -i production site.yml
```

Once we have our server with docker on it we will continue to step 4 where we'll build the docker images and run the containers using Ansible.


