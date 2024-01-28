#!/bin/bash

mongorestore --host 0.0.0.0 --port 27017 /data
systemctl start cron
