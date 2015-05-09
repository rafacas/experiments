# Step 6 - Monitoring

The last step of this exercise is monitoring this small infrastructure. A straightforward approach would be running a monitoring agent (such as Nagios, Zabbix or a Sensu agent). It is not a good solution as it goes against Docker’s philosophy of having one clearly identified task in each container. 

On the other hand, installing an agent in the docker host is a good idea (not in every container) so we'll monitor the server status. We'll install a Nagios agent (the Nagios server will connect to it through SSH) and apart from the basic linux checks we'll add the [check_docker](https://github.com/newrelic/check_docker) plugin. It gets some basic statistics reported by the Docker daemon and additionally validates the absence of Ghost containers.

But how can we monitor the containers? There is a very good article about [Gathering LXC and Docker containers metrics](http://blog.docker.com/2013/10/gathering-lxc-docker-containers-metrics/) in case we need to get a specific value so we could write a custom script.

If we connect to the docker host we can have an overview of the containers status with ```docker stats```:

```
$ sudo docker stats loadbalancer webapp1 webapp2
CONTAINER           CPU %               MEM USAGE/LIMIT       MEM %               NET I/O
loadbalancer        0.00%               1.273 MiB/490.1 MiB   0.26%               9.77 KiB/8.162 KiB
webapp1             0.00%               1.332 MiB/490.1 MiB   0.27%               23.61 KiB/27.14 KiB
webapp2             0.00%               1.309 MiB/490.1 MiB   0.27%               4.48 KiB/3.89 KiB
```

There are also specific tools to understand the resource usage and performance characteristics of the running containers, such as [cAdvisor](https://github.com/google/cadvisor) or.

It would be interesting having an external time series database like [InfluxDB](http://influxdb.com/) or [Prometheus](http://prometheus.io/) where the docker hosts and containers send their metrics.
