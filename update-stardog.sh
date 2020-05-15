#!/bin/bash

git pull
echo "copy updated ontology"
docker cp ./ontology/. kind-control-plane:/var/opt/
stardogpod=$(kubectl get pods --selector=app=stardog | cut -d ' ' -f 1 | grep stardog)
echo "update db"
kubectl exec -it $stardogpod bash /var/opt/stardog/create-sensors-db.sh
