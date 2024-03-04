#!/bin/bash

podman kube play 1_mongo.yaml --network nf_separated_container_core:ip=172.61.0.1
