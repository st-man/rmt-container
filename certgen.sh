#!/bin/bash
# Install 
## Create  RMT Certificates
#### Change hostname and ip_address to your data.
export CA_PWD="_rmt"
export hostname=$HOSTNAME
export ip_address=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
openssl genrsa -aes256 -passout env:CA_PWD -out ./ssl/rmt-ca.key 2048
openssl req -x509 -new -nodes -key ./ssl/rmt-ca.key -sha256 -days 1825 -out ./ssl/rmt-ca.crt -passin env:CA_PWD -config ./ssl/rmt-ca.cnf
openssl genrsa -out ./ssl/rmt-server.key 2048
openssl req -new -key ./ssl/rmt-server.key -out ./ssl/rmt-server.csr -config ./ssl/rmt-server.cnf
openssl x509 -req -in ./ssl/rmt-server.csr -out ./ssl/rmt-server.crt -CA ./ssl/rmt-ca.crt -CAkey ./ssl/rmt-ca.key -passin env:CA_PWD -days 1825 -sha256 -CAcreateserial -extensions v3_server_sign -extfile ./ssl/rmt-server.cnf
cat ./ssl/rmt-ca.crt >> ./ssl/rmt-server.crt
chmod 0600 ./ssl/*
chmod 0644 ./ssl/rmt-ca.crt
