# Step 4 - Deploying containers with Ansible

Now that we have our production server up and running we are going to deploy the docker containers.

Instead of creating the docker images in the docker host we have created a couple of repositories in [Docker Hub](https://hub.docker.com/):
* [load_balancer](https://registry.hub.docker.com/u/rafacas/load_balancer/)
* [webapp](https://registry.hub.docker.com/u/rafacas/webapp/)

One way to automate the image creation would be to have a Jenkins process that uploads a new image every time there is a change in the Dockerfile. And instead of uploading it to Docker Hub a private registry would be better (depending on the application, maybe we want it to be public).

Once we have the images in the registry we run ansible. It will pull the images and create the containers:

```
$ cd ansible
$ ansible-playbook -i production site.yml
[...]
GATHERING FACTS ***************************************************************
ok: [docker1]

TASK: [Web application containers] ********************************************
changed: [docker1] => (item=webapp1)
changed: [docker1] => (item=webapp2)

TASK: [Load balancer container] ***********************************************
changed: [docker1]

PLAY RECAP ********************************************************************
docker1                    : ok=15   changed=10   unreachable=0    failed=0
```

If we ssh into our docker host, ```docker1```, we'll see all the containers have been created:

```
$ ssh vagrant@docker1
vagrant@docker1:~$ sudo docker ps
CONTAINER ID        IMAGE                          COMMAND                CREATED             STATUS              PORTS                            NAMES
ca9c6bd690cc        rafacas/load_balancer:latest   "nginx -g 'daemon of   7 minutes ago       Up 7 minutes        0.0.0.0:80->80/tcp, 443/tcp      loadbalancer
ec3e89bf908d        rafacas/webapp:latest          "nginx -g 'daemon of   7 minutes ago       Up 7 minutes        443/tcp, 0.0.0.0:32769->80/tcp   webapp2
f04b84d155f9        rafacas/webapp:latest          "nginx -g 'daemon of   7 minutes ago       Up 7 minutes        443/tcp, 0.0.0.0:32768->80/tcp   webapp1
```

If we now open a browser and go to ```http://docker1``` we should see the static HTML page. 

```
$ curl http://docker1
<!DOCTYPE html>
<head>
    <meta charset="utf-8">
    <title>Cool Application</title>
</head>
<body>
    This is a pretty cool webapp
</body>
</html>
```

