#!/bin/bash

cat << EOF >> /etc/crontab

* * * * * root cp -rf /var/lib/mongodb/* /data/
EOF
