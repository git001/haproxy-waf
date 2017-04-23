# haproxy-waf [![Build Status](https://travis-ci.org/git001/haproxy-waf.svg?branch=master)](https://travis-ci.org/git001/haproxy-waf)

## Introduction

The main work is based on Thierry Fournier patches and of course the SPOE feature of haproxy.

You can see the start and following discussion on the haproxy mailing list.
https://www.mail-archive.com/haproxy@formilux.org/msg25681.html

You are able with this patches to use haproxy as SSL terminator and WAF (Web Application Firewall) based on mod_security.

## requirements

You will need this tools to run this docker file on centos

```
yum -y install docker bash-completion git
systemctl start docker
```

## build 

Now you can clone & build this repo with common commands

```
git clone https://github.com/git001/haproxy-waf.git
cd haproxy-waf
docker build -t haproxy-waf .
```

## test

You can see if the build works with the `docker run` command

```
docker run --entrypoint /usr/local/sbin/haproxy --rm haproxy-waf -vv
```

# haproxy use

I have uploaded the image into docker hub

```
https://hub.docker.com/r/me2digital/haproxy-waf/
```

from where you can use this image with the following command.

```
$ docker run --rm -it --name my-running-haproxy \
    -e TZ=Europe/Vienna \
    -e STATS_PORT=1999 \
    -e STATS_USER=aaa \
    -e STATS_PASSWORD=bbb \
    -e SYSLOG_ADDRESS=127.0.0.1:8514 \
    -e SERVICE_TCP_PORT=13443 \
    -e SERVICE_NAME=test-haproxy \
    -e SERVICE_DEST_PORT=8080 \
    -e SERVICE_DEST='1.2.3.4;5.6.7.8;80.44.22.7' \
    me2digital/haproxy-waf /bin/bash
```

The output of the command above should be something like this

```
Current ENV Values
===================
SERVICE_NAME        :test-haproxy
SERVICE_DEST        :1.2.3.4;5.6.7.8;80.44.22.7
SERVICE_DEST_PORT   :8080
TZ                  :Europe/Vienna
SYSLOG_ADDRESS      :127.0.0.1:8514
CONFIG_FILE         :
given DNS_SRV001    :
given DNS_SRV002    :
===================
compute DNS_SRV001  :8.8.8.8
compute DNS_SRV002  :8.8.4.4
using CONFIG_FILE   :/tmp/haproxy.conf
...
```

# waf use

TODO

