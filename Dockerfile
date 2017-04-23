FROM centos:latest

# take a look at http://www.lua.org/download.html for
# newer version

ENV HAPROXY_MAJOR=1.8 \
    HAPROXY_VERSION=1.8.x \
    HAPROXY_MD5=ed84c80cb97852d2aa3161ed16c48a1c \
    LUA_VERSION=5.3.4 \
    LUA_URL=http://www.lua.org/ftp/lua-5.3.4.tar.gz \
    LUA_MD5=53a9c68bcc0eda58bdc2095ad5cdfc63 \
    MODSEC_URL=https://www.modsecurity.org/tarball/2.9.1/modsecurity-2.9.1.tar.gz \
    MODSEC_SHA256=958cc5a7a7430f93fac0fd6f8b9aa92fc1801efce0cda797d6029d44080a9b24

# RUN cat /etc/redhat-release
# RUN yum provides "*lib*/libc.a"

COPY containerfiles /

RUN set -x \
  && yum -y update \
  && export buildDeps='pcre-devel openssl-devel gcc make zlib-devel readline-devel openssl patch git apr-devel apr-util-devel gcc make libevent-devel libxml2-devel libcurl-devel httpd-devel pcre-devel yajl-devel' \
  && yum -y install pcre openssl-libs zlib bind-utils curl iproute tar strace libevent libxml2 libcurl apr apr-util ${buildDeps} \
  && curl -SL ${LUA_URL} -o lua-${LUA_VERSION}.tar.gz \
  && curl -SL ${MODSEC_URL} -o modsecurity-2.9.1.tar.gz \
  && echo "${LUA_MD5} lua-${LUA_VERSION}.tar.gz" | md5sum -c \
  && echo "${MODSEC_SHA256} modsecurity-2.9.1.tar.gz" | sha256sum -c \
  && mkdir -p /usr/src/lua \
  && tar -xzf lua-${LUA_VERSION}.tar.gz -C /usr/src/lua --strip-components=1 \
  && rm lua-${LUA_VERSION}.tar.gz \
  && make -C /usr/src/lua linux test install \
  && tar xfvz modsecurity-2.9.1.tar.gz \
  && cd modsecurity-2.9.1 \
  && ./configure \
      --prefix=$PWD/INSTALL \
      --disable-apache2-module \
      --enable-standalone-module \
      --enable-pcre-study \
      --without-lua \
      --enable-pcre-jit \
  && make -C standalone install \
  && mkdir -p $PWD/INSTALL/include \
  && cp standalone/*.h $PWD/INSTALL/include \
  && cp apache2/*.h $PWD/INSTALL/include \
  && cd /usr/src \
  && git clone http://git.haproxy.org/git/haproxy.git/ \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0002-BUG-MINOR-change-header-declared-function-to-static-.patch \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0003-REORG-spoe-move-spoe_encode_varint-spoe_decode_varin.patch \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0004-MINOR-Add-binary-encoding-request-header-sample-fetc.patch \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0005-MINOR-proto-http-Add-sample-fetch-wich-returns-all-H.patch \
  && patch -d /usr/src/haproxy -p 1 -i /patches/0006-MINOR-Add-ModSecurity-wrapper-as-contrib.patch \
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
  && cd /usr/src/haproxy /contrib/modsecurity \
  && make MODSEC_INC=/root/modsecurity-2.9.1/INSTALL/include MODSEC_LIB=/root/modsecurity-2.9.1/INSTALL/lib APACHE2_INC=/usr/include/httpd APR_INC=/usr/include/apr-1 \
  && mkdir -p /usr/local/etc/haproxy \
  && mkdir -p /usr/local/etc/haproxy/ssl \
  && mkdir -p /usr/local/etc/haproxy/ssl/cas \
  && mkdir -p /usr/local/etc/haproxy/ssl/crts \
  && cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
  && rm -rf /usr/src/haproxy /usr/src/lua /usr/src/000* \
  && yum -y autoremove $buildDeps \
  && yum -y clean all

#         && openssl dhparam -out /usr/local/etc/haproxy/ssl/dh-param_4096 4096 \

# I know it's not very efficient to copy this files twice but 
# I accept this small inefficient
COPY containerfiles /

RUN chmod 555 /container-entrypoint.sh

EXPOSE 13443

ENTRYPOINT ["/container-entrypoint.sh"]

#CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.conf"]
#CMD ["haproxy", "-vv"]
