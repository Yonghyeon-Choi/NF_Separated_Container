#!/bin/bash

apt-get update && apt-get install gnupg
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update && apt-get install -y mongodb-org
systemctl restart mongod && systemctl enable mongod && systemctl status mongod

mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install nodejs -y

curl -fsSL https://open5gs.org/open5gs/assets/webui/install | bash -

systemctl stop mongod
CONIP=172.61.0.1
sed -i "s/127.0.0.1/$CONIP/g" /etc/mongod.conf
systemctl start mongod
systemctl status mongod
sleep 10
netstat -nap | grep "$CONIP:27017"

# mongosh "mongodb://$CONIP:27017/open5gs"
# db.accounts.find()

sed -i "s/localhost/$CONIP/g" /usr/lib/node_modules/open5gs/server/index.js
sed -i "s/9999/3000/g" /usr/lib/node_modules/open5gs/server/index.js
