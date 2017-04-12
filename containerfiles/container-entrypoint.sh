#!/bin/bash

# set -x

echo "Current ENV Values"
echo "==================="
echo "SERVICE_NAME        :"${SERVICE_NAME}
echo "SERVICE_DEST        :"${SERVICE_DEST}
echo "SERVICE_DEST_PORT   :"${SERVICE_DEST_PORT}
echo "TZ                  :"${TZ}
echo "SYSLOG_ADDRESS      :"${SYSLOG_ADDRESS}
echo "CONFIG_FILE         :"${CONFIG_FILE}
echo "given DNS_SRV001    :"${DNS_SRV001}
echo "given DNS_SRV002    :"${DNS_SRV002}

if [ x${DEBUG} != x ]; then

echo "HAProxy Version:"

/usr/local/sbin/haproxy -vv

fi

if [ x"${SERVICE_DEST}" = x ];
then
  echo "Error the SERVICE_DEST MUST be defined"
  exit 1
fi

if [ x"${SERVICE_NAME}" = x ];
then
  echo "Error the SERVICE_NAME MUST be defined"
  exit 1
fi

if [ x"${SERVICE_DEST_PORT}" = x ];
then
  echo "Error the SERVICE_DEST_PORT MUST be defined"
  exit 1
fi

if [ x"${SYSLOG_ADDRESS}" = x ];
then
  echo "Error the SYSLOG_ADDRESS MUST be defined"
  exit 1
fi

if [ x"${DNS_SRV001}" = x ];
then
  dns_counter=1
  for i in $( egrep ^nameserver /etc/resolv.conf|awk '{print $2}' ) ; do
    export DNS_SRV00${dns_counter}=$i
    let "dns_counter++"
  done
fi

if [ x"${DNS_SRV001}" = x ];
then
  echo "Error the DNS_SRV001 MUST be defined"
  exit 1
fi

if [ x"${DNS_SRV002}" = x ];
then
  export DNS_SRV002=${DNS_SRV001}
fi

echo "==================="
echo "compute DNS_SRV001  :"${DNS_SRV001}
echo "compute DNS_SRV002  :"${DNS_SRV002}

if [ x"${CONFIG_FILE}" = x ];
then
  counter=0
  for i in $( echo ${SERVICE_DEST}| sed -e 's/;/ /g') ; do
    server_lines=${server_lines}$(echo -e server "${SERVICE_NAME}_"$(printf "%03i" "$counter") ${i}:${SERVICE_DEST_PORT} resolvers mydns check \\\\\n)
    let "counter++"
  done
  CONFIG_FILE=/tmp/haproxy.conf
  # ${server_lines}
  sed -e "s/server_lines/${server_lines}/" /usr/local/etc/haproxy/haproxy.conf.template > ${CONFIG_FILE}
fi

echo "using CONFIG_FILE   :"${CONFIG_FILE}

if [ x${DEBUG} != x ]; then
  exec /usr/local/sbin/haproxy -f ${CONFIG_FILE} -d
else
  exec /usr/local/sbin/haproxy -f ${CONFIG_FILE} -db
fi
