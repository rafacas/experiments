# Three-node Infrastructure

I've been asked to build a three-node infrastructure: one nginx load balancer and two app servers (it doesn't matter whether it’s Ruby/Rails, Python/Django, PHP, or static HTML). This small infrastructure should be firewalled and monitored (suppose a monitoring server is already in place).

I'm going to use this opportunity to learn [Docker](https://www.docker.com/) and keep learning about [Ansible](http://www.ansible.com/home).

These are the steps I'm going to follow to create the infrastructure:

* [Step 0]() - Development environment.
* [Step 1]() - Infrastructure images and containers.
* [Step 2]() - Docker Compose.
* [Step 3]() - Building and provisioning a production server (docker host).
* [Step 4]() - Deploying containers with Ansible.
* [Step 5]() - Firewalling.
* [Step 6]() - Monitoring.
