# Step 5 - Firewalling

We've enabled UFW with a *deny* policy, that means all traffic is denied by default.

To be able to use Ansible and SSH into the machine we've opened port 22.

The 3 containers expose only the 80 port and only the load balancer maps it with the 80 port of the host so we've added a UFW rule to allow incoming traffic to that port.

Docker uses a bridge (```docker0```) to manage container networking. By default, UFW drops all forwarding traffic. As a result, for Docker to run when UFW is enabled, you must set UFW's forwarding policy appropriately. Also, it's recommended to configure a DNS server for use by Docker. All this changes are explained in the [Docker documentation about Ubuntu](http://docs.docker.com/installation/ubuntulinux/#enable-ufw-forwarding) and was done in *step3* by the Ansible role ```docker_ubuntu```.

**NOTE**: TESTING NEEDED!
