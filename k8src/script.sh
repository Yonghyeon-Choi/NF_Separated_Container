#!/bin/bash


podman network create --driver macvlan \
         --subnet=192.168.2.0/24 \
         --gateway=192.168.2.254 \
         --opt parent=eno1 dn

podman network create --driver macvlan \
         --subnet=172.61.0.0/24 \
         --gateway=172.61.0.254 \
         --opt parent=eno4 core
        #--driver bridge
	#--interface-name=eno4

podman kube play 1_mongo.yaml --network core:ip=172.61.0.1
podman kube play 5_udr.yaml --network core:ip=172.61.0.20
podman kube play 5_udm.yaml --network core:ip=172.61.0.12
podman kube play 5_smf.yaml --network core:ip=172.61.0.4
podman kube play 5_amf.yaml --network core:ip=172.61.0.5
podman kube play 5_upf.yaml --network core:ip=172.61.0.7 --network dn:ip=192.168.2.224
podman kube play 5_nrf.yaml --network core:ip=172.61.0.10
podman kube play 5_scp.yaml --network core:ip=172.61.0.200
podman kube play 5_ausf.yaml --network core:ip=172.61.0.11
podman kube play 5_pcf.yaml --network core:ip=172.61.0.13
podman kube play 5_nssf.yaml --network core:ip=172.61.0.14
podman kube play 5_bsf.yaml --network core:ip=172.61.0.15


