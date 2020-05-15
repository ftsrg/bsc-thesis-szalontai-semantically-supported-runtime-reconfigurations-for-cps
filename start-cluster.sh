#!/bin/bash

# _          _                          _
#| | ___   _| |__   ___ _ __ _ __   ___| |_ ___  ___
#| |/ / | | | '_ \ / _ \ '__| '_ \ / _ \ __/ _ \/ __|
#|   <| |_| | |_) |  __/ |  | | | |  __/ ||  __/\__ \
#|_|\_\\__,_|_.__/ \___|_|  |_| |_|\___|\__\___||___/

kind delete cluster
kind create cluster --config kind-config.yml
cp ~/.kube/config /d/Dokumentumok/szakdoga/kubeconfig
#     _                _
# ___| |_ __ _ _ __ __| | ___   __ _
#/ __| __/ _` | '__/ _` |/ _ \ / _` |
#\__ \ || (_| | | | (_| | (_) | (_| |
#|___/\__\__,_|_|  \__,_|\___/ \__, |
#                              |___/

docker cp ./ontology/. kind-control-plane:/var/opt/
docker cp ./stardog/. kind-control-plane:/var/opt/

kubectl create -f ./stardog/stardog-deployment.yml
kubectl create -f ./stardog/stardog-studio-deployment.yml
echo "starting stardog on localhost:30820"


getnotrunningpods=$(kubectl get pods | grep -E -- 'ContainerCreating|Pending' | wc -l)
while [ $getnotrunningpods -ge 1 ]
do
        echo "waiting for start..."
        sleep 10
        getnotrunningpods=$(kubectl get pods | grep -E -- 'ContainerCreating|Pending' | wc -l)
done


echo "forwarding ports"
kubectl port-forward deployment.apps/stardog-deployment 30820:5820 &>/dev/null &
kubectl port-forward deployment.apps/stardog-studio-deployment 30080:80 &>/dev/null &
sleep 5
echo "adding sensors to db"
stardogpod=$(kubectl get pods --selector=app=stardog | cut -d ' ' -f 1 | grep stardog)
kubectl exec -it $stardogpod bash /var/opt/stardog/create-sensors-db.sh

# ____ _____ ___
#|  _ \_   _|_ _|
#| |_) || |  | |
#|  _ < | |  | |
#|_| \_\|_| |___|

kind load docker-image dds_sensor:1.0
kind load docker-image rtiroutingservice_fahrenheittocelsius:1.0
kind load docker-image rticlouddiscoveryservice:1.0

kubectl apply -f ./kubernetes/deployment/rticloudservicediscovery.yml
kubectl apply -f ./kubernetes/configmaps/

