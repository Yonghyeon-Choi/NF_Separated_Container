#!/bin/bash

sed -i "s/ExecStart=\/usr\/bin\/mongod --config \/etc\/mongod.conf/ExecStart=\"\/usr\/bin\/mongod --config \/etc\/mongod.conf; sleep 10; mongorestore --host 0.0.0.0 --port 27017 \/data\"/g" /etc/systemd/system/multi-user.target.wants/mongod.service
systemctl restart mongod

sed -i'' -re "/After/a\Wants=mongodb.service mongod.service" /etc/systemd/system/multi-user.target.wants/cron.service

cat << EOF >> /etc/crontab

* * * * * root mongodump --host 0.0.0.0 --port 27017 --out /data
EOF
