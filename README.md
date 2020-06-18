# rloomans/cgiproxy

Packaging of [CGIProxy](https://www.jmarshall.com/tools/cgiproxy) as a docker container.

## Usage


```
docker run \
    --name cgiproxy \
    --hostname cgiproxy \
    -p 8443:443 \
    -e PUID=<UID> -e PGID=<GID> \
    -e TZ=<timezone> \
    rloomans/cgiproxy:latest
```

Use a browser to go to `https://<DOCKER_HOST>:8443/` and you will automatically redirected to `https://<DOCKER_HOST>:8443/<RANDOM_STRING>/` where `<RANDOM_STRING>` is regenerated each time the container is built.

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port `-p external:internal` - what this shows is the port mapping from internal to external of the container.
So `-p 8443:443` would expose port 80 from inside the container to be accessible from the host's IP on port 8443
`https://<DOCKER_HOST>:8443/` would show you what's running INSIDE the container on port 443.


* `-p 8443:443` - the port for the webUI
* `-e PGID` for for GroupID - see below for explanation
* `-e PUID` for for UserID - see below for explanation
* `-e TZ` for timezone setting, eg Africa/Johannesburg


This container is based on [phusion/baseimage](https://github.com/phusion/baseimage-docker). For shell access whilst the container is running do `docker exec -it cgiproxy /bin/bash`.


## Info

* To monitor the logs of the container in realtime `docker logs -f cgiproxy`.

