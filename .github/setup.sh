set -e

CONF=/etc/postgresql/$PG_VERSION/main
echo "VER=#{$PG_VERSION}"
echo "CONF=#{$CONF}"

cp .github/pg_hba.conf $CONF

mkdir .cert
chmod 700 .cert
cd .cert

openssl req -new -nodes -text -out ca.csr -keyout ca-key.pem -subj "/CN=certificate-authority"
openssl x509 -req -in ca.csr -text -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey ca-key.pem -out ca-cert.pem
openssl req -new -nodes -text -out server.csr -keyout server-key.pem -subj "/CN=pg-server"
openssl x509 -req -in server.csr -text -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
openssl req -new -nodes -text -out client.csr -keyout client-key.pem -subj "/CN=crystal_ssl"
openssl x509 -req -in client.csr -text -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem
chmod 600 *

cp ca-cert.pem root.crt
mv client-cert.pem crystal_ssl.crt
mv client-key.pem crystal_ssl.key
openssl verify -CAfile root.crt crystal_ssl.crt

cp server-cert.pem $CONF
cp server-key.pem  $CONF/
cp ca-cert.pem     $CONF/
chown postgres     $CONF/*.pem
echo "ssl = on" >> $CONF/postgresql.conf
echo "ssl_cert_file = '$CONF/server-cert.pem'" >> $CONF/postgresql.conf
echo "ssl_key_file  = '$CONF/server-key.pem'"  >> $CONF/postgresql.conf
echo "ssl_ca_file   = '$CONF/ca-cert.pem'"     >> $CONF/postgresql.conf

pg_ctlcluster $PG_VERSION main restart
