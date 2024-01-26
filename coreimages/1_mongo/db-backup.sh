#!/bin/bash


cat << EOF >> /etc/crontab

* * * * * root mongodump --host 0.0.0.0 --port 27017 --out /data
EOF
