#!/bin/bash

set -x

NAME="lyj"

PKI_DIR="$(pwd)/${NAME}"
rm -rfv ${PKI_DIR}
mkdir -p ${PKI_DIR}
#chmod -R 0600 ${PKI_DIR}
#cd ${PKI_DIR}
touch ${PKI_DIR}/index.txt; echo 1000 > ${PKI_DIR}/serial
mkdir -p ${PKI_DIR}/newcerts

PKI_CNF=${PKI_DIR}/openssl.cnf
cp -rfv /etc/ssl/openssl.cnf ${PKI_CNF}


sed -i '/^dir/   s:=.*:= '${PKI_DIR}':'                      ${PKI_CNF}
sed -i '/.*Name/ s:= match:= optional:'                    ${PKI_CNF}

sed -i '/organizationName_default/    s:= .*:= WWW Ltd.:'  ${PKI_CNF}
sed -i '/stateOrProvinceName_default/ s:= .*:= London:'    ${PKI_CNF}
sed -i '/countryName_default/         s:= .*:= GB:'        ${PKI_CNF}

sed -i '/default_days/   s:=.*:= 3650:'                    ${PKI_CNF} ## default usu.: -days 365
sed -i '/default_bits/   s:=.*:= 4096:'                    ${PKI_CNF} ## default usu.: -newkey rsa:2048

rm -rfv ${NAME}-nec.cfg
cp -rfv nec.cfg ${NAME}-nec.cfg
sed -i 's/NAME-server/'${NAME}'-server/g' ${NAME}-nec.cfg
sed -i 's/NAME-client/'${NAME}'-client/g' ${NAME}-nec.cfg

cat ${NAME}-nec.cfg >> ${PKI_CNF}

echo "###############################################################################"
echo "Gen Server File"
echo "###############################################################################"
CA_KEY=${PKI_DIR}/newcerts/ca.key
CA_CRT=${PKI_DIR}/newcerts/ca.crt
SERVER_KEY=${PKI_DIR}/newcerts/${NAME}-server.key
SERVER_CSR=${PKI_DIR}/newcerts/${NAME}-server.csr
SERVER_CRT=${PKI_DIR}/newcerts/${NAME}-server.crt
#CA_KEY=ca.key
#CA_CRT=ca.crt
#SERVER_KEY=${NAME}-server.key
#SERVER_CSR=${NAME}-server.csr
#SERVER_CRT=${NAME}-server.crt

openssl req -batch -nodes -new -keyout "${CA_KEY}" -out "${CA_CRT}" -x509 -config ${PKI_CNF}  ## x509 (self-signed) for the CA
openssl req -batch -nodes -new -keyout "${SERVER_KEY}" -out "${SERVER_CSR}" -subj "/CN=${NAME}-server" -config ${PKI_CNF}
openssl ca  -batch -keyfile "${CA_KEY}" -cert "${CA_CRT}" -in "${SERVER_CSR}" -out "${SERVER_CRT}" -config ${PKI_CNF} -extensions ${NAME}-server

#openssl req -batch -nodes -new -keyout "ca.key" -out "ca.crt" -x509 -config ${PKI_CNF}  ## x509 (self-signed) for the CA
#openssl req -batch -nodes -new -keyout "my-server.key" -out "my-server.csr" -subj "/CN=my-server" -config ${PKI_CNF}
#openssl ca  -batch -keyfile "ca.key" -cert "ca.crt" -in "my-server.csr" -out "my-server.crt" -config ${PKI_CNF} -extensions my-server

echo "###############################################################################"
echo "Gen Client File"
echo "###############################################################################"
CLIENT_KEY=${PKI_DIR}/newcerts/${NAME}-client.key
CLIENT_CSR=${PKI_DIR}/newcerts/${NAME}-client.csr
CLIENT_CRT=${PKI_DIR}/newcerts/${NAME}-client.crt
openssl req -batch -nodes -new -keyout "${CLIENT_KEY}" -out "${CLIENT_CSR}" -subj "/CN=${NAME}-client" -config ${PKI_CNF}
openssl ca  -batch -keyfile "${CA_KEY}" -cert "${CA_CRT}" -in "${CLIENT_CSR}" -out "${CLIENT_CRT}" -config ${PKI_CNF} -extensions ${NAME}-client

