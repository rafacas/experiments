# Step 2 - Docker Compose

It can get pretty tedious building images and running and linking containers manually. In this step we will use [Docker Compose](http://docs.docker.com/compose/) to define our small infrastructure and automate all those processes.

We define the services that make up our app in the following file ```docker-compose.yml``` 

```
loadbalancer:
    build: ./load_balancer
    links:
        - webapp1:webapp1
        - webapp2:webapp2
    ports:
        - "80:80"
webapp1:
    build: ./webapp
    ports:
        - "80"
webapp2:
    build: ./webapp
    ports:
        - "80"
```

When we run ```docker-compose up```, Compose will build the images, and start everything up:

```
$ docker-compose up -d
Creating step2_webapp2_1...
Building webapp2...
Step 0 : FROM nginx
 ---> 02a791aafe15
Step 1 : COPY content /usr/share/nginx/html
 ---> 3a7de75d01d3
Removing intermediate container 720810f6aed0
Successfully built 3a7de75d01d3
Creating step2_webapp1_1...
Building webapp1...
Step 0 : FROM nginx
 ---> 02a791aafe15
Step 1 : COPY content /usr/share/nginx/html
 ---> Using cache
 ---> 3a7de75d01d3
Successfully built 3a7de75d01d3
Creating step2_loadbalancer_1...
Building loadbalancer...
Step 0 : FROM nginx
 ---> 02a791aafe15
Step 1 : COPY nginx.conf /etc/nginx/nginx.conf
 ---> 240a096f773b
Removing intermediate container 606d4d5f1bec
Successfully built 240a096f773b
```

We use ```-d``` to run the services in the background.

We use ```docker-compose``` ps to see what is currently running:

```
$ docker-compose ps
        Name                 Command          State               Ports
------------------------------------------------------------------------------------
step2_loadbalancer_1   nginx -g daemon off;   Up      443/tcp, 0.0.0.0:80->80/tcp
step2_webapp1_1        nginx -g daemon off;   Up      443/tcp, 0.0.0.0:32783->80/tcp
step2_webapp2_1        nginx -g daemon off;   Up      443/tcp, 0.0.0.0:32782->80/tcp
```

To stop our services:

```
$ docker-compose stop
Stopping step2_loadbalancer_1...
Stopping step2_webapp1_1...
Stopping step2_webapp2_1...
```

Compose is great for development environments, staging servers, and CI but it isn't recommended to use in production yet so we'll use Ansible for production.

