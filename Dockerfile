FROM centos:latest

# take a look at http://www.lua.org/download.html for
# newer version

ENV HAPROXY_MAJOR=1.7 \
    HAPROXY_VERSION=1.7.5 \
    HAPROXY_MD5=ed84c80cb97852d2aa3161ed16c48a1c \
    LUA_VERSION=5.3.4 \
    LUA_URL=http://www.lua.org/ftp/lua-5.3.4.tar.gz \
    LUA_MD5=53a9c68bcc0eda58bdc2095ad5cdfc63

# RUN cat /etc/redhat-release
# RUN yum provides "*lib*/libc.a"

# see http://git.haproxy.org/?p=haproxy-1.6.git;a=blob_plain;f=Makefile;hb=HEAD
# for some helpful navigation of the possible "make" arguments

RUN set -x \
  && yum -y update \
  && export buildDeps='pcre-devel openssl-devel gcc make zlib-devel readline-devel openssl ' \
  && yum -y install pcre openssl-libs zlib bind-utils curl iproute tar strace ${buildDeps} \
  && curl -SL ${LUA_URL} -o lua-${LUA_VERSION}.tar.gz \
  && echo "${LUA_MD5} lua-${LUA_VERSION}.tar.gz" | md5sum -c \
  && mkdir -p /usr/src/lua \
  && tar -xzf lua-${LUA_VERSION}.tar.gz -C /usr/src/lua --strip-components=1 \
  && rm lua-${LUA_VERSION}.tar.gz \
  && make -C /usr/src/lua linux test install \
  && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
  && echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
  && curl -vo /usr/src/0001-BUG-MINOR-change-header-declared-function-to-static-.patch http://www.arpalert.org/0001-BUG-MINOR-change-header-declared-function-to-static-.patch \
  && curl -vo /usr/src/0002-MINOR-Add-binary-encoding-request-sample-fetch.patch http://www.arpalert.org/0002-MINOR-Add-binary-encoding-request-sample-fetch.patch \
  && curl -vo /usr/src/0003-MINOR-Add-ModSecurity-wrapper-as-contrib.patch http://www.arpalert.org/0003-MINOR-Add-ModSecurity-wrapper-as-contrib.patch \
  && mkdir -p /usr/src/haproxy \
  && tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
  && rm haproxy.tar.gz \
  && patch -d /usr/src/haproxy -p 1 /usr/src/0001-BUG-MINOR-change-header-declared-function-to-static-.patch \
  && patch -d /usr/src/haproxy -p 1 /usr/src/0002-MINOR-Add-binary-encoding-request-sample-fetch.patch \
  && patch -d /usr/src/haproxy -p 1 /usr/src/0003-MINOR-Add-ModSecurity-wrapper-as-contrib.patch \
  && make -C /usr/src/haproxy \
		TARGET=linux2628 \
		USE_PCRE=1 \
		USE_OPENSSL=1 \
		USE_ZLIB=1 \
        USE_LINUX_SPLICE=1 \
        USE_TFO=1 \
        USE_PCRE_JIT=1 \
        USE_LUA=1 \
		all \
		install-bin \
  && mkdir -p /usr/local/etc/haproxy \
  && mkdir -p /usr/local/etc/haproxy/ssl \
  && mkdir -p /usr/local/etc/haproxy/ssl/cas \
  && mkdir -p /usr/local/etc/haproxy/ssl/crts \
  && cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
  && rm -rf /usr/src/haproxy /usr/src/lua \
  && yum -y autoremove $buildDeps \
  && yum -y clean all

#         && openssl dhparam -out /usr/local/etc/haproxy/ssl/dh-param_4096 4096 \

COPY containerfiles /

RUN chmod 555 /container-entrypoint.sh

EXPOSE 13443

ENTRYPOINT ["/container-entrypoint.sh"]

#CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.conf"]
#CMD ["haproxy", "-vv"]
