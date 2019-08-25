# Supported tags and respective `Dockerfile` links

-	[`latest` (*/debian/stretch-slim/Dockerfile*)](https://github.com/wilkesystems/docker-fcgwrap/blob/master/debian/stretch-slim/Dockerfile)

# fcgiwrap on Debian Stretch
fcgiwrap is a simple server for running CGI applications over FastCGI. Its goal 
is to provide clean CGI support to the nginx webserver, although can be used with others.

## Get Image
[Docker hub](https://hub.docker.com/r/wilkesystems/fcgiwrap)

```bash
docker pull wilkesystems/fcgiwrap
```

## How to use this image

```bash
$ docker run -d wilkesystems/fcgiwrap
```

- `-e FCGI_CHILDREN=...` Defines the number of the children
- `-e FCGI_SOCKET=...` Sets the socket path
- `-e FCGI_SOCKET_MODE=...` Sets the socket mode
- `-e FCGI_SOCKET_OWNER=...` Sets the socket owner
- `-e FCGI_SOCKET_GROUP=...` Sets the socket group
- `-e FCGI_USER=...` Sets the User
- `-e FCGI_GROUP=...` Sets the Group
- `-e FCGI_UID=...` Sets the User ID
- `-e FCGI_GID=...` Sets the Group ID

## Auto Builds
New images are automatically built by each new library/debian push.

## Package: fcgiwrap
Package: [fcgiwrap](https://packages.debian.org/stretch/fcgiwrap)

fcgiwrap is a simple server for running CGI applications over FastCGI. Its goal is to provide clean CGI support to the nginx webserver, although can be used with others.

fcgiwrap is lightweight and has no configuration, making it possible to use the same pool to run different sites.
