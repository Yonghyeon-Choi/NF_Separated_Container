#!/bin/bash

out=`podman ps --format "{{.Names}}"`
cons=(`echo $out | tr '\n' ' '`)

echo ${cons[@]}
for con in "${cons[@]}"
do
	podman generate kube "$con" > "$con".yaml
	echo "$con"
done

