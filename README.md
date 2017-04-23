# haproxy-waf [![Build Status](https://travis-ci.org/git001/haproxy-waf.svg?branch=master)](https://travis-ci.org/git001/haproxy-waf)

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
