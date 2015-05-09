# Step 1 - Infrastructure images and containers

In this step we are going to create the images and containers needed for the small infrastructure. That is, one image and one container for the load balancer and one image and two containers for the webapp.

We will use the official nginx docker image for both images.

This article has great [tips for deploying nginx official image with docker](https://blog.docker.com/2015/04/tips-for-deploying-nginx-official-image-with-docker/).

## Webapp 

We will use a static HTML page as the *webapp*, so the Dockerfile we use to create the webapp image is pretty simple:

```
FROM nginx

COPY content /usr/share/nginx/html
```

We use the ```nginx``` official image as the base of our image. Then we copy the static page into ```/usr/share/nginx/html```.

Then we build it:

```
$ cd webapp
$ docker build -t rafacas/webapp .
Sending build context to Docker daemon 3.584 kB
Sending build context to Docker daemon
Step 0 : FROM nginx
 ---> 02a791aafe15
Step 1 : COPY content /usr/share/nginx/html
 ---> 611e003ca41e
Removing intermediate container ae47dad0dff9
Successfully built 611e003ca41e
```

And check ```docker images``` shows it:

```
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
rafacas/webapp              latest              611e003ca41e        2 minutes ago       93.45 MB
```

Now we will create 2 containers (webapp1 and webapp2) using this image:

```
$ docker run --name webapp1 -P -d rafacas/webapp
c97641899d59fb4dc402605c3e0b711ebcd7136014d2e422234c42e8fdc340b6
$ docker run --name webapp2 -P -d rafacas/webapp
dfe17e0aafeacb737b238b08f1c3e57981fce9f673b85ec7489f82cf6274a915
$ docker ps
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                                           NAMES
dfe17e0aafea        rafacas/webapp:latest   "nginx -g 'daemon of   14 seconds ago      Up 13 seconds       0.0.0.0:32776->80/tcp, 0.0.0.0:32777->443/tcp   webapp2
c97641899d59        rafacas/webapp:latest   "nginx -g 'daemon of   20 seconds ago      Up 19 seconds       0.0.0.0:32775->80/tcp, 0.0.0.0:32774->443/tcp   webapp1
```

So now we have a couple of containers running nginx and serving our static HTML page.

The ```-P``` flag tells Docker to map any required network ports inside our container to our host. To get the page directly from ```webapp1``` for example, we can use:

```
$ curl $(boot2docker ip):32776
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

Although it makes more sense to use a web browser for this ;)

## Load balancer 

We create a simple configuration for load balancing with nginx that looks like the following:

```
http {

    upstream webapp {
          least_conn;
          server webapp1:80 weight=10 max_fails=3 fail_timeout=30s;
          server webapp2:80 weight=10 max_fails=3 fail_timeout=30s;
    }

    server {
          listen 80;

          location / {
            proxy_pass http://webapp;
          }
    }
}
```

It listens on port 80, and proxies requests to the upstream server webapp.

We've specified the least-connected load balancing, nginx will try not to overload a busy application server with excessive requests, distributing the new requests to a less busy server instead.

We've also used weighted load balancing (with the ```weight``` parameter) and health checks (with the ```max_fails``` and ```fail_timeout``` parameters).

We create the ```load_balancer``` image:

```
$ docker build -t rafacas/load_balancer .
Sending build context to Docker daemon 3.072 kB
Sending build context to Docker daemon
Step 0 : FROM nginx
 ---> 02a791aafe15
Step 1 : COPY nginx.conf /etc/nginx/nginx.conf
 ---> deee48ee0f84
Removing intermediate container d37de737a702
Successfully built deee48ee0f84
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
rafacas/load_balancer       latest              deee48ee0f84        8 seconds ago       93.45 MB
rafacas/webapp              latest              611e003ca41e        46 minutes ago      93.45 MB
nginx                       latest              02a791aafe15        1 day ago           93.45 MB
```

We have used the hostnames ```webapp1``` and ```webapp2``` in the nginx configuration but we haven't update the ```/etc/hosts``` file in the image because they don't have static IPs, they can change every time a container is started. Docker provides a linking system that allows you to link multiple containers together and send connection information from one to another.

## Linking containers

To establish links, Docker relies on the names of your containers. We have named our webapp containers: ```webapp1``` and ```webapp2```. One of the features of the linking system is that it adds a host entry for the source container to the ```/etc/hosts``` file. If we link the ```load_balancer``` container with the webapp containers we won't have to create both entries in the ```/etc/hosts``` file of the load balancer.

```
$ docker run -d -p 80:80 --name load_balancer \
> --link webapp1:webapp1 --link webapp2:webapp2 rafacas/load_balancer
fb0e15a5aaaa02b9660ab1c2f7caac53256179d09de377b8f41e4d97315f3eeb
$ docker ps
CONTAINER ID        IMAGE                          COMMAND                CREATED             STATUS              PORTS                                           NAMES
fb0e15a5aaaa        rafacas/load_balancer:latest   "nginx -g 'daemon of   4 seconds ago       Up 2 seconds        0.0.0.0:80->80/tcp, 443/tcp                     load_balancer
dfe17e0aafea        rafacas/webapp:latest          "nginx -g 'daemon of   55 minutes ago      Up 55 minutes       0.0.0.0:32776->80/tcp, 0.0.0.0:32777->443/tcp   webapp2
c97641899d59        rafacas/webapp:latest          "nginx -g 'daemon of   55 minutes ago      Up 55 minutes       0.0.0.0:32775->80/tcp, 0.0.0.0:32774->443/tcp   webapp1
```

We have mapped the host 80 port to the load balancer 80 port so:

```
$ curl $(boot2docker ip)
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

We now have a load balancer with two app servers.

