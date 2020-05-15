#!/bin/bash

cp /home/jeno96/.kube/config /d/Dokumentumok/szakdoga/kubeconfig

docker rm kubelabel
docker run -it --name kubelabel -v /d/Dokumentumok/szakdoga/kubeconfig:/root/.kube/config --network=host localhost:5001/kubelabel

